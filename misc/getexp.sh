#!/bin/bash

file=$1
STAMP=$(date +%Y-%m-%d)
OUTFILE="${STAMP}_getexp-output.csv"

# If input file is not there, write error and exit
[ ! -f $file ] && { echo "$file file not found"; exit 99; }


# Function to enumerate hosts in a netgroup
# ngenum <LDAP_SERVER> <BASE_DN> <CN>
function ngenum () {
    nghosts=$(ldapsearch -h $1 -x -b $2 cn=$3 | grep '^nisNetgroupTriple' | awk '{print $2}' | sed 's/[(),-]//g')
    echo $nghosts
}

# Function to guess if "host" is a netgroup or not
# ngtest <HOST>
function ngtest () {
    local host=$1
    local type="unknown"
    # If it's an IP, we know it's a host
    if [[ $host =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        type="host"
    elif [[ $host = *"."*  ]]; then
         type="host"
    elif [[ $host = *"_"* ]]; then
        type="netgroup"
    elif [[ $host = *"@"* ]]; then
        type="netgroup"
    else
        ping -c 1 -W 1 ${host} &> /dev/null
        if [ $? -eq 0 ]; then
            type="host"
        elif [ $? -eq 1 ]; then
            res=$(getent hosts $host | awk '{print $1}')
            if [ -z $res ]; then
                type="unknown"
            else
                type="host"
            fi
        fi
    fi
    echo $type
}

# Output writer function
function output () {
    local line=$1
    echo $line >> "$OUTFILE"
}

# Read the input csv file
# srcf = Source_Filer
# srcvf = Source_Vfiler
# srcv = Source_Volume
# ldape = Ldap_Enabled
# ldapng = Ldap_Netgroup
# ldapsrv = Ldap_Servers
# ldapsrvp = Ldap_SrvPref

while IFS=$'\t' read srcf srcvf srcv ldape ldapng ldapsrv ldapsrvp
do
    # Going to add our hosts to this empty array
    # FHOSTS = Final_Host_List
    FHOSTS=()
    # One variable for all variables	 to write easier
    # going to append 1 or 2 fields throughout
    LINE="$srcf,$srcvf,$srcv"
    echo "Processing ${srcf}:${srcvf}:${srcv}"
    # Using the capitalized version of all varaibles for work (quotes removed)
    # all lowercased variables for writing output
    SRCF=${srcf//\"/}
    SRCVF=${srcvf//\"/}
    SRCV=${srcv//\"/}
    LDAPE=${ldape//\"/}
    LDAPNG=${ldapng//\"/}
    LDAPSRV=${ldapsrv//\"/}
    LDAPSRVP=${ldapsrvp//\"}
    # LDAP servers could be more than one, so putting
    # them into an array
    LDAPSRV=($LDAPSRV)
    LDAPSRVP=($LDAPSRVP)
    echo "Source Filer: $SRCF"
    echo "Source Vfiler: $SRCVF"
    echo "Source Volume: $SRCV"
    echo "Ldap Enabled: $LDAPE"
    #echo "Ldap Base: $LDAPB"
    #echo "Ldap Passwd: $LDAPP"
    #echo "Ldap Group: $LDAPG"
    echo "Ldap Ngroup: $LDAPNG"
    echo "Ldap Servers 1: ${LDAPSRV[0]}"
    echo "Ldap ServPref 1: ${LDAPSRVP[0]}"
    sleep 3
    # Checking if we need to query filer or vfiler or if vfiler is empty
    if [ "$srcvf" == "vfiler0" ]; then
        NFSSRV=$srcf
    elif [ -z "$srcvf" ]; then
        COMMENT="SourceVfilerEmpty"
        LINE="$LINE,$FHOSTS,$COMMENT"
        output $LINE
        continue
    else
        NFSSRV=$srcvf
    fi
    # If NFSSRV (filer or vFiler) doesn't respond to pings, write the line and contine
    ping -c 1 -W 1 ${NFSSRV} &> /dev/null
    if [ $? -ne 0 ]; then
	echo "${NFSSRV} did not respond to ping"
        COMMENT="SourceVfilerNoPing"
        LINE="$LINE,$FHOSTS,$COMMENT"
        output $LINE
        continue
    # If ping succeeds, execute a showmount to grab the export list
    else
        EXPLIST=($(showmount --no-headers -e $NFSSRV | grep $srcv | awk '{print $2}' | sed 's/,/ /g'))
        # If showmount -e doesn't return anything, write output with COMMENT
        if [ -z "$EXPLIST" ]; then
            echo "Volume is not exported to any hosts"
            COMMENT="VolumeNotExported"
            LINE="$LINE,$FHOSTS,$COMMENT"
            output $LINE
            continue
        # If volume is exported to everyone, we'll use showmount -a
        elif [[ $EXPLIST = *"everyone"* ]]; then
	    echo "${NFSSRV}: using showmount -a"
            EXPLIST=($(showmount --no-headers -a $NFSSRV | grep $srcv | cut -d':' -f1 | tr '\n' ' '))
            # If showmount -a shows no hosts mount, write the line and continue
            if [ -z "$EXPLIST" ]; then
		echo "${NFSSRV} exported to everyone, but no hosts mounting"
                COMMENT="ExportedEveryoneNoMounts"
                LINE="$LINE,$FHOSTS,$COMMENT"
                output $LINE
                continue
            # We got some hosts from showmount -a, now process them
            # showmount -a will not show netgroups, so no need to process them
            else
                for H in ${EXPLIST[@]}; do
                    if [[ $host =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                        ping -c 1 -W 1 $H &> /dev/null
                        if [ $? -ne 0 ]; then
                            # Host is not on the network
                            continue
                        else
                            # Host is on the network, get hostname
                            HNAME=$(getent hosts $H | awk '{print $2}')
                            # If can't get hostname, add IP
                            if [ -z "$HNAME" ]; then
                                FHOSTS+=("$H")
                            # If we get the hostname, add it
                            else
                                if [[ $HNAME = *"namnas"* ]]; then
                                    # Host is migration host, skipping
                                    continue
                                else
                                    FHOSTS+=("$HNAME")
                                fi
                            fi
                        fi
                    else
                        if [[ $HNAME = *"namnas"* ]]; then
                            # Host is migration host, skipping
                            continue
                        else
                            ping -c 1 -W 1 $H &> /dev/null
                            if [ $? -ne 0 ]; then
                                continue
                            else
                                FHOSTS+=("$H")
                            fi
                        fi
                    fi
                done
                COMMENT="showmount-a"
		FHOSTS=$(printf ";%s" "${FHOSTS[@]}")
		FHOSTS=${FHOSTS:1}
                LINE="$LINE,$FHOSTS,$COMMENT"
                output $LINE
            fi
        else
            # Processing beings if we got data from showmount -e
            for H in ${EXPLIST[@]}; do
                # Try to detect (ngtest) if host is a host or netgroup
                RES=$(ngtest $H)
                case "$RES" in
                    host)
                        if [[ $H =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                            ping -c 1 -W 1 $H &> /dev/null
                            if [ $? -ne 0 ]; then
                                # Host is not on the network
                                continue
                            else
                                # Host is on the network, try to resolve name
                                HNAME=$(getent hosts $H | awk '{print $2}')
                                if [ -z "$HNAME" ]; then
                                    # Cannot resolve hostname, but IP is alive.
                                    # So adding it to Final_Hosts
                                    FHOSTS+=("$H")
                                elif [[ $HNAME = *"namnas"* ]]; then
                                    # Host is a migration host, not adding to
                                    # final list
                                    continue
                                else
                                    # Resolved the name, so adding it
                                    FHOSTS+=("$HNAME")
                                fi
                            fi
                        elif [[ $H = *"namnas"* ]]; then
                            # Migration host added by name in export list
                            # skipping
                            continue
                        else
                            ping -c 1 -W 1 $H > /dev/null
                            if [ $? -ne 0 ]; then
                                # Host is not on the network
                                continue
                            else
                                # Add hostname to final list
                                FHOSTS+=("$H")
                            fi
                        fi
                        ;;
                    netgroup)
                        # Remove @ symbol if it exists
                        H=${H//\@/}
                        if [[ $LDAPE -ne "on" ]]; then
                            echo "Netgroup ${H} found for ${SRCVF}:${SRCV}, but no LDAP info exists"
                        else
                            if [ -z "$LDAPSRVP" ]; then
				echo "ngenum ${LDAPSRV[0]} $LDAPNG $H"
                                NGHOSTS=($(ngenum "${LDAPSRV[0]}" "$LDAPNG" "$H"))
                                if [ -z "$NGHOSTS" ]; then
                                    # Netgroup is empty
                                    continue
                                else
                                    for H in ${NGHOSTS[@]}; do
                                        ping -c 1 -W 1 $H &> /dev/null
                                        if [ $? -eq 0 ]; then
                                            FHOSTS+=("$H")
                                        else
                                            # Host is not on the network
                                            continue
                                        fi
                                    done
                                fi
                            else
				echo "ngenum ${LDAPSRVP[0]} $LDAPNG $H"
                                NGHOSTS=($(ngenum "${LDAPSRVP[0]}" "$LDAPNG" "$H"))
                                if [ -z "$NGHOSTS" ]; then
                                    # Netgroup is empty
                                    continue
                                else
                                    for H in ${NGHOSTS[@]}; do
                                        ping -c 1 -W 1 $H &> /dev/null
                                        if [ $? -eq 0 ]; then
                                            FHOSTS+=("$H")
                                        else
                                            # Host is not on the network
                                            continue
                                        fi
                                    done
                                fi
                            fi
                        fi
                        ;;
                    unknown)
                        # According to the ngtest function, if the type is
                        # unknown, we know it is not a host, but could still
                        # be a netgroup, so let's try it:
                        if [ -z "$LDAPE" ]; then
                            # This must mean it's a dead host
                            continue
                        elif [ -z "$LDAPSRVP" ]; then
                            NGHOSTS=$(ngenum "${LDAPSRV[0]}" "$LDAPNG" "$H")
                            if [ -z $NGHOSTS ]; then
                                # No hosts returned in the lookup
                                # Either dead host, non-existent netgroup
                                # or empty netgroup
                                continue
                            else
                                for H in ${NGHOSTS[@]}; do
                                    ping -c 1 -W 1 $H &> /dev/null
                                    if [ $? -eq 0 ]; then
                                        FHOSTS+=("$H")
                                    else
                                        # Host is not on the network
                                        continue
                                    fi
                                done
                            fi
                        else
                            NGHOSTS=$(ngenum "${LDAPSRVP[0]}" "$LDAPNG" "$H")
                            if [ -z "$NGHOSTS" ]; then
                                # No hosts returned in the lookup
                                # Either dead host, non-existent netgroup
                                # or empty netgroup
                                continue
                            else
                                for H in ${NGHOSTS[@]}; do
                                    ping -c 1 -W 1 $H &> /dev/null
                                    if [ $? -eq 0 ]; then
                                        FHOSTS+=("$H")
                                    else
                                        # Host is not on the network
                                        continue
                                    fi
                                done
                            fi
                        fi
                        ;;
                    *)
                        echo "Host detection failed for ${SRCVF}:${SRCV} - $H"
                        ;;
                esac
            done
            COMMENT="showmount-e"
	    FHOSTS=$(printf ";%s" "${FHOSTS[@]}")
	    FHOSTS=${FHOSTS:1}
            LINE="$LINE,$FHOSTS,$COMMENT"
            output $LINE
        fi
    fi
done < $file
