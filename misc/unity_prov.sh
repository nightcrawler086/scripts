#!/bin/bash

# Input File
INFILE=$1
# Make sure we can find the file
[ ! -f $INFILE ] && { echo "$FILE file not found"; exit 99; }
# Datestamp
STAMP=$(date +%Y-%m-%d-%H%M%S)
# Log file
OUTFILE="${STAMP}_unity-prov-log.txt"
# Define other log levels in their own variables
# so I don't have to reset the level each time
LOG_DEF="INFO"
LOG_ERR="ERROR"
LOG_WRN="WARN"
# Default Domain for CIFS servers is NAM
DEF_DOMAIN="nam.nsroot.net"
# Default OU is the NAS Team's OU
DEF_OU="OU=Servers,OU=NAS,OU=GWIS,OU=INFRA"
# Default CAVA Configuration File
DEF_CAVA_CONFIG="virtuschecker.conf"
# Default DNS Server String
DEF_DNS_STR="192.193.215.65,192.193.215.69,192.193.215.73"
# Setting default interface type to "production"
DEF_INT_TYPE="production"
# TODO
#
# Steps to functionalize:
#
# 1. Create NAS Server (PROD) - DONE
# 2. Delete default NFS server (PROD) - DONE
# 3. Create Interface (PROD)
# 4. Configure DNS (PROD)
# 5. Create CIFS Server and Join Domain (PROD)
# 6. Set CIFS Local Admin Password (PROD)
# 7. Configure/Enable CAVA on NAS Server (PROD)
# 8. CIFS server mapping and adding viruschecker group
# 9. SMB Signing on NAS server
# 10. Create NAS Server (COB) - DONE?
# 11. Delete default NFS server (COB) - DONE?
# 12. Set NAS Server as destination (COB)
# 13. Create Replication for NAS Server (PROD)
# 14. Set interface with "overridden" option (COB)
# 15. NDMP user setup (COB)
# 16. Create Filesystem (PROD)
# 17. Create CIFS Share (PROD)
# 18. Create qtree (NOT GOING TO BE DONE WITH THIS SCRIPT)
# 19. Create CIFS share using new qtree (separate script?)
# 20. Delete original share created at volume level (PROD)
# 21. Create Filesystem (COB)
# 22. Create Replication session for Filesystem (PROD)
# 23. Configure CAVA with override option on NAS Server (COB)

# log <MSG> <FILE> 
function log () {
    local MESSAGE=$1
    local LOGFILE=$OUTFILE
    # Default log level is INFO
    local LEVEL=${2:-${LOG_DEF}}
    local STAMP=$(date "+%Y-%m-%d %H:%M:%S")
    local LINE="${STAMP} | ${LEVEL} | ${MESSAGE}"
    echo ${LINE} | tee -a "${LOGFILE}"
}
# Create the NAS Server
function nas_server_create_cifs () {
    local UNITY=$1
    local NAS_SERVER_NAME=$2
    local SP=$3
    local POOL_ID=$4
    # This will test to see if the NAS Server exists already
    EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/server -name ${NAS_SERVER_NAME} show)
    if [ $? -eq 0 ]; then
         LOG_MSG="NAS Server '${NAS_SERVER_NAME}' already exists!"
         log "${LOG_MSG}"
         return 1
    else
        LOG_MSG="NAS Server '${NAS_SERVER_NAME}' does not yet exist"
        log "${LOG_MSG}"
    fi
    # Create the server
    LOG_MSG="Attempting to create NAS Server '${NAS_SERVER_NAME}'"
    log "${LOG_MSG}"
    NAS_CREATE_RESULT=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/server create \
        -name ${NAS_SERVER_NAME} -sp ${SP} -pool ${POOL_ID} -enablePacketReflect yes)
    if [ $? -eq 0 ]; then
         NAS_SERVER_ID=$(awk '{print $3}' <<< $(echo ${NAS_CREATE_RESULT}))
         LOG_MSG="NAS Server ${NAS_SERVER_NAME} created with ID: ${NAS_SERVER_ID}"
         log "${LOG_MSG}"
    else
        LOG_MSG="NAS Server ${NAS_SERVER_NAME} failed to create with the following error"
        log "${LOG_MSG}" "${LOG_ERR}"
        log "${NAS_CREATE_RESULT}" "${LOG_ERR}"
        return 1
    fi
    # Filter out the server ID from the creation result
    # There seems to be an ID for each object, and a internal server ID.
    # The internal server ID gets returned when the server is created, so we
    # can use that and save us from running another query.
    NAS_SERVER_NFS_ID=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/nfs \
        -serverName ${NAS_SERVER_NAME} show | awk 'NR==1{print $4}')
    # Delete NFS server that got created with it
    NFS_SERVER_DEL_RESULT=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/nfs -id ${NAS_SERVER_NFS_ID} delete)
    if [ $? -eq 0 ]; then
         LOG_MSG="NFS Server on '${NAS_SERVER_NAME}' with ID '${NAS_SERVER_NFS_ID}' was deleted successfully"
         log "${LOG_MSG}"
    else
        LOG_MSG="Failed to delete NFS server with ID '${NAS_SERVER_NFS_ID}' on '${NAS_SERVER_NAME}' "
        log "${LOG_MSG}" "${LOG_ERR}"
        log "${NAS_CREATE_RESULT}" "${LOG_ERR}"
        return 1
    fi
    # Return the ID of the NAS Server we created.
    echo ${NAS_SERVER_ID}
}
function get_nas_server_id () {
	local UNITY=$1
	local NAS_SERVER_NAME=$2
	NAS_SERVER_ID=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/server -name ${NAS_SERVER_NAME} show | \
	    awk 'NR==1{print $4}')
    if [ $? -eq 0 ]; then
    	#LOG_MSG="Found NAS Server '${NAS_SERVER_NAME}' with ID '${NAS_SERVER_ID}'"
    	#log "${LOG_MSG}"
	echo ${NAS_SERVER_ID}
    else
        LOG_MSG="Failed to delete NFS server with ID '${NAS_SERVER_NFS_ID}' on '${NAS_SERVER_NAME}' "
        log "${LOG_MSG}" "${LOG_ERR}"
        log "${NAS_CREATE_RESULT}" "${LOG_ERR}"
        return 1
    fi
}
function nas_server_int_create () {
    local UNITY=$1
    local NAS_SERVER_NAME=$2
    local FSN_PORT=$3
    local IP_ADDR=$4
    local IP_NETMASK=$5
    local IP_GW=$6
    local ROLE=${7:-${DEF_INT_TYPE}}
    # This will test to see if the interface exists already
    EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/if -serverName $NAS_SERVER_NAME \
    	show -output csv -filter "ID,IP address")
    if [ $? -eq 0 ]; then
        LOG_MSG="Some intefaces on NAS Server '${NAS_SERVER_NAME}' already exist"
        log "${LOG_MSG}"
	$EXISTING_IP_MATCH=$(echo "$EXIST" | awk -F, '$2 == "\"$IP_ADDR\"" {print $2}')
	if [ -z ${EXISTING_IP_MATCH} ]; then
		LOG_MSG="Did not find an existing interface with IP '${IP_ADDR}'"
		log "${LOG_MSG}"
	else
		LOG_MSG="Found existing interface with IP '${IP_ADDR}'"
		log "${LOG_MSG}"
		return 1
	fi
    fi
    # The below returns the ID of the interface created
    # do we need this for anything?
    IF_CREATE_RESULT=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/if create -serverName \
        ${NAS_SERVER_NAME} -port ${FSN_PORT} -addr ${IP_ADDR} -netmask ${IP_NETMASK} -gateway ${IP_GW} -role backup)
    if [ $? -eq 0 ]; then
        NAS_IF_ID=$(awk '{print $3}' <<< $(echo ${IF_CREATE_RESULT}))
        LOG_MSG="Interface ${IP_ADDR} on ${NAS_SERVER_NAME} created successfully"
        log "${LOG_MSG}"
	echo "${NAS_IF_ID}"
    else
        LOG_MSG="Interface '${IP_ADDR}' failed to create on '${NAS_SERVER_NAME}'"
        log "${LOG_MSG}" "${LOG_ERR}"
        log "${NAS_CREATE_RESULT}" "${LOG_ERR}"
        return 1
    fi
}
function set_dns () {
    local NAS_SERVER_ID=$1
    local DOMAIN=$2
    local DNS_SERVER_STR=$3
    # First check to see if it's already configured
    #EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/dns -server ${NAS_SERVER_ID} show)
    #if [ -z $EXIST ]; then
        # If nothing is in the variable, then no DNS is set
     #   LOG_MSG="DNS is not setup for '${NAS_SERVER_ID}'"
      #  log "${LOG_MSG}"
      #  SET_DNS_RESULT=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/dns \
            #-server ${NAS_SERVER_ID} set -name ${DOMAIN} ${DNS_SERVER_STR})
   # else
    #fi

    #
    # Test result of above command
    #
}
function cifs_server_create () {
    # cifs_server_create { ${UNITY} ${NAS_SERVER} ${USER} } [ ${CIFS_SERVER} ${NETBIOS} ${DOMAIM} ${OU} ]
    local UNITY=$1
    local NAS_SERVER=$2
    local USER=$3
    # By default the CIFS server name and the NETBIOS name will match the NAS Server Name
    # These variables can be overridden by passing their values explicitly to the function
    local CIFS_SERVER=${4:-${2}}
    local NETBIOS=${5:-${2}}
    # Default value is set at top of script
    local DOMAIN=${6:-${DEF_DOMAIN}}
    # Default value is set at top of script
    local OU=${7:-${DEF_OU}}
    $EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/cifs -name ${NAS_SERVER} show)
    if [ $? -eq 0 ]; then
        # The awk statement here is untested
        CIFS_SERVER_ID=$(awk '{print $3}' <<< $(echo ${EXIST}))
        LOG_MSG="A CIFS server for '${NAS_SERVER}' already exists"
        log "${LOG_MSG}" "${LOG_WRN}"
		return 2
    else
        LOG_MSG="Could not find an existing CIFS Server for '${NAS_SERVER}'.  Attempting to create."
        log "${LOG_MSG}"
        $CIFS_SERVER_CREATE=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/cifs create-serverName ${NAS_SERVER} -name \
            ${CIFS_SERVER} -netbiosName ${NETBIOS} -domain ${DOMAIN} -username ${USER} -passwdSecure -orgUnit ${OU})
        if [ $? -eq 0 ]; then
            LOG_MSG="CIFS Server '${CIFS_SERVER}' created successfully on NAS Server '${NAS_SERVER}'"
            log "${LOG_MSG}"
            # awk out the ID of the CIFS server
            echo ${CIFS_SERVER_ID}
        else
            LOG_MSG="Failed to create CIFS Server '${CIFS_SERVER}' on NAS Server '${NAS_SERVER}'"
            log "${LOG_MSG}" "${LOG_ERR}"
            return 1
        fi
    fi
}
function set_cava () {
    local UNITY=$1
    local NAS_SERVER=$2
    local NAS_SERVER_ID=$3
    local CAVA_CONFIG_FILE=${4:-${DEF_CAVA_CONFIG}}
    # First test to be sure the file exists
    [ ! -f $CAVA_CONFIG_FILE ] && \
        { log "Could not fine CAVA configuration file $CAVA_CONFIG_File" "${LOG_ERR}"; exit 99; }
    # This will replace the blanket viruschecker.conf file with the current NAS Server for upload
    NEW="CIFSserver=${NAS_SERVER}"
    sed -E -i .bak "s/^CIFSserver=[A-Z]{10}[0-9]{4}$/${NEW}/g" ${CAVA_CONFIG_FILE}
    TEST=$(grep '^CIFSserver' ${CAVA_CONFIG_FILE})
    if [ "$TEST" == "CIFSserver=${NAS_SERVER}" ]; then
        ORIG=$(grep '^CIFSserver' ${CAVA_CONFIG_FILE}.bak)
        LOG_MSG="Replaced original string '${ORIG}' with '${NEW}' in viruschecker.conf"
        log "${LOG_MSG}"
        CAVA_CONFIG=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept -upload f ${CAVA_CONFIG_FILE} /net/nas/cava \
            -server ${NAS_SERVER_ID} -type config)
        if [ $? -eq 0 ]; then
            LOG_MSG="Uploaded CAVA configuration file '${CAVA_CONFIG_FILE}' successfully for ${NAS_SERVER}"
            log "${LOG_MSG}"
        else
            LOG_MSG="Failed to upload CAVA configuration file '${CAVA_CONFIG_FILE}'"
            log "${LOG_MSG}" "${LOG_ERR}"
            return 1
        fi
    else
        LOG_MSG="String replacement in '${CAVA_CONFIG_FILE}' did not work.  CAVA configuration for '${NAS_SERVER}' failed"
        log "${LOG_MSG}" "${LOG_ERR}"
    fi
}
function set_nas_server_dest () {
    local UNITY=$1
    local NAS_SERVER_NAME=$2
    ####### Need to grep out replDest from below show command and test the value
    EXIST=$(uemcli -noHeader -sslPolicy accept /net/nas/server -name ${NAS_SERVER_NAME} show)
    #########
    if [ "$EXIST" == REPLACEME ]; then
        LOG_MSG="NAS Server '${NAS_SERVER_NAME}' is already set as a replication destination"
        log "${LOG_MSG}" "${LOG_WRN}"
        return 2
    else
        SET_DST_RESULT=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/server -name ${NAS_SERVER_NAME} \
            set -replDest yes)
    fi
}
#function nas_server_rep () {
#    # Don't think I can do this, can we call a remote system?
#}
function set_int_override () {
    local NAS_SERVER=$1
    # I think all of the properties we need can be queried
    # since the interface should already exist:
    #
    # NAS Server SP?
    #   This would be to get the FSN port from the right SP
    # Interface ID
    # FSN Port ID
    # IP Address
    # Netmask
    # Gateway
    #
    RES=$(uemcli -noHeaer -sslPolicy accept /net/nas/if -id ${INT_ID} set \
        -port ${FSN} -addr ${IP_ADDR} -netmask ${IP_MASK} -gateway ${IP_GW} -replSync overridden})
}
function fs_create () {
    local UNITY=$1
    local NAME=$2
    local NAS_SERVER_ID=$3
    local POOL_ID=$4
    # Size is always expected in GB
    local SIZE=$5
    local TYPE=$6
    # Let's check to be sure the FS size isn't too crazy
    if (( $SIZE > 1536 )); then
        LOG_MSG="Filesystem size specified is ${SIZE}GB, this is too large to create"
        log "${LOG_MSG}" ${LOG_ERR}
        return 1
    fi
    # Does FS exist?
    EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /stor/prov/fs -name ${NAME} show)
    if [ $? -eq 0 ]; then
         LOG_MSG="The filesystem '${NAME}' already exists!"
         log "${LOG_MSG}" ${LOG_ERR}
         return 1
    else
        LOG_MSG="The filesystem '${NAME}' does not exist yet."
        log "${LOG_MSG}"
        # the following few lines will check the subscription percentage of the
        # pool, and if the pool is 100% subscribed or more, we will not create
        # the filesystem.  However, I cannot check the filesystem will make the
        # pool more than 100% subscribed (not enough math binaries on the
        # system)
        POOL_SUB=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /stor/config/pool show| grep Subscription | awk '{print $4}')
        if (( ${POOL_SUB%\%*} >= 100 )); then
            # Pool is oversubscribed, do not create
            LOG_MSG="This NAS is already 100% subscribed or more.  Cannot create any more filesystems"
            log "${LOG_MSG}" ${LOG_ERR}
            return 1
        else
            LOG_MSG="The pool is currently ${POOL_SUB} subscribed, continuing with filesystem creation"
            log "${LOG_MSG}"
            # Create Filesystem
            #echo "Command: uemcli -d ${UNITY} -noHeader -sslPolicy accept /stor/prov/fs create -name ${NAME} -server  ${NAS_SERVER_ID} -pool ${POOL_ID} -size ${SIZE}G -dataReduction yes -advnacedDedupe yes -type ${TYPE}"
            FS_CREATE=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /stor/prov/fs create -name ${NAME} -server \
                ${NAS_SERVER_ID} -pool ${POOL_ID} -size ${SIZE}G -dataReduction yes -advancedDedup yes -type ${TYPE})
            if [ $? -eq 0 ]; then
                 LOG_MSG="The filesystem '${NAME}' was created successfully!"
                 log "${LOG_MSG}"
            else
                LOG_MSG="The filesystem '${NAME}' failed to create."
                log "${LOG_MSG}" "${LOG_ERR}"
                log "${FS_CREATE}"
            fi
        fi
    fi
}
function ndmp_user_create () {
    local UNITY=$1
    local NAS_SERVER_ID=$2
    EXIST=$(uemcli -d ${UNITY} -noHeader -sslPolicy accept /net/nas/ndmp -server ${NAS_SERVER_ID}
    show)
}
# Slice the files we need to read 
# Unique NAS Servers first
awk -F, '!seen[$8]++' $INFILE > ${STAMP}_unity-nas-servers.tmp
NAS_SERVERS="./${STAMP}_unity-nas-servers.tmp"

# This first while loop will be operating on the unique list of 
# NAS Servers. All NAS Server operations should go here
# Columns from SOD Sheet:
#
# Status
# Provisioning TC
# Prod Physical Device (Unity)
# SP
# Pool
# FS
# FSN
# VDM
# IP
# Netmask
# Broadcast
# Prod QIP
# FS Size
# COB Unity
# COB SP
# COB Pool
# COB FS
# COB FSN
# COB VDM
# COB IP
# COB Netmask
# COB Broadcast
# COB QIP
# Qtree
# Backup server name
# Backup Server IP
# Backup Netmask
# Backup gateway
# Security Style

while IFS=, read A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC; do
    # Skipping friendly names in the while statement
    # Too many columns would make the line way too long
    # We'll se friendly variable names here
    TC=${B//\"/}
    PROD_UNITY=${C//\"/}
    SP=${D//\"/}
    POOL=${E//\"/}
    FS=${F//\"/}
    FSN=${G//\"/}
    NAS_SERVER=${H//\"/}
    IP_ADDR=${I//\"/}
    IP_MASK=${J//\"/}
    IP_GW=${K//\"/}
    PROD_QIP=${L//\"/}
    FS_SIZE=${M//\"/}
    COB_UNITY=${N//\"/}
    COB_SP=${O//\"/}
    COB_POOL=${P//\"/}
    COB_FS=${Q//\"/}
    COB_FSN=${R//\"/}
    COB_NAS_SERVER=${S//\"/}
    COB_IP_ADDR=${T//\"/}
    COB_IP_MASK=${U//\"/}
    COB_IP_GW=${V//\"/}
    COB_QIP=${W//\"/}
    QTREE=${X//\"/}
    BKUP_QIP=${Y//\"/}
    BKUP_IP_ADDR=${Z//\"/}
    BKUP_IP_MASK=${AA//\"/}
    BKUP_IP_GW=${AB//\"/}
    SEC_STYLE=${AC//\"/}
    # Just testing that I have the right variable:
    #echo "Variables inside the NAS Server loop"
    #echo "${PROD_UNITY} | ${SP} | ${NAS_SERVER} | ${FS} | ${FS_SIZE} | ${FS_TYPE} | ${IP_ADDR} | ${IP_MASK} | ${IP_GW} | ${COB_UNITY}"
    # Get the pool ID for use will all the commands
    POOL_ID=$(uemcli -d ${PROD_UNITY} -noHeader -sslPolicy accept /stor/config/pool show | awk 'NR==1{print $4}')
    if [ "$POOL" = "$POOL_ID" ]; then
	LOG_MSG="The pool ID in the input file '${POOL}' matches the pool ID on the system '${POOL_ID}'"
    	log "${LOG_MSG}"
    else
	# Lab box has multiple pools, but not expected on the prod boxes
	# Could add a check for multiple pools, but would need to change the query above
	LOG_MSG="The pool ID in the input file '${POOL}' does not match the pool ID on the system '${POOL_ID}'"
    	log "${LOG_MSG}" "${LOG_WRN}"
	LOG_MSG="We will use the pool ID queried from the system"
    	log "${LOG_MSG}" "${LOG_WRN}"
    fi	
    # Get FSN devices from each SP
    # Is this going to work?  Doesn't seem to read line-by-line
    #FSN_DEVICES=$(uemcli -d ${PROD_UNITY} -noHeader -sslPolicy accept /net/fsn show -output csv -filter "SP,ID")
    #SPA_FSN=$(echo "$FSN_DEVICES" | awk -F, '$1 == "\"spa\"" {print $2}')
    #SPB_FSN=$(echo "$FSN_DEVICES" | awk -F, '$1 == "\"spb\"" {print $2}')
    # Var test
    #echo "${PROD_UNITY} | ${NAS_SERVER} | ${SP} | ${POOL_ID}"
    # Start by creating the nas server
    NEW_NAS_SERVER_ID=$(nas_server_create_cifs "${PROD_UNITY}" "${NAS_SERVER}" "${SP}" "${POOL_ID}")
    if [ "$NEW_NAS_SERVER_ID" == 1 ]; then
    	LOG_MSG="The function 'nas_server_create_cifs' failed to create '${NAS_SERVER}'"
    	log "${LOG_MSG}"
    	continue
    fi
    # These need to be uncommented for production runs
    #if [ ${SP} == "SPA" ]; then
    #	RESULT=$(nas_server_int_create "${UNITY}" "${NAS_SERVER}" "${SPA_FSN}" "${IP_ADDR}" "${IP_MASK}" "${IP_GW}" "production")
    #elif [ ${SP} == "SPB" ]; then
    #	RESULT=$(nas_server_int_create "${UNITY}" "${NAS_SERVER}" "${SPB_FSN}" "${IP_ADDR}" "${IP_MASK}" "${IP_GW}" "production")
    #fi	
    # Check to see if the nas server exists
    # then create if it doesn't
    # slice the input file based on the NAS server
    # for loop for all filesystems
    #NAS_SERVER_ID=$(nas_server_create_cifs "${PROD_UNITY}" "${NAS_SERVER}" "${SP}" "${POOL_ID}") 
    #echo "returned nas server id:  ${NAS_SERVER_ID}"
done < $NAS_SERVERS
# This next loop will iterate over the entire input file
# All filesystem related operations go here.
while IFS=, read A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD; do
    # Skipping friendly names in the while statement
    # Too many columns would make the line way too long
    # We'll se friendly variable names here
    TC=${B//\"/}
    echo "TC = ${TC}"
    PROD_UNITY=${C//\"/}
    echo "PROD_UNITY = ${PROD_UNITY}"
    SP=${D//\"/}
    echo "SP = ${SP}"
    POOL=${E//\"/}
    echo "POOL = ${POOL}"
    FS=${F//\"/}
    echo "FS = ${FS}"
    FSN=${G//\"/}
    echo "FSN = ${FSN}"
    NAS_SERVER=${H//\"/}
    echo "NAS_SERVER = ${NAS_SERVER}"
    IP_ADDR=${I//\"/}
    echo "IP_ADDR = ${IP_ADDR}"
    IP_MASK=${J//\"/}
    echo "IP_MASK = ${IP_MASK}"
    IP_GW=${K//\"/}
    echo "IP_GW = ${IP_GW}"
    PROD_QIP=${L//\"/}
    echo "PROD_QIP = ${PROD_QIP}"
    FS_SIZE=${M//\"/}
    echo "FS_SIZE = ${FS_SIZE}"
    COB_UNITY=${N//\"/}
    echo "COB_UNITY = ${COB_UNITY}"
    COB_SP=${O//\"/}
    echo "COB_SP = ${COB_SP}"
    COB_POOL=${P//\"/}
    echo "COB_POOL = ${COB_POOL}"
    COB_FS=${Q//\"/}
    echo "COB_FS = ${COB_FS}"
    COB_FSN=${R//\"/}
    echo "COB_FSN = ${COB_FSN}"
    COB_NAS_SERVER=${S//\"/}
    echo "COB_NAS_SERVER = ${COB_NAS_SERVER}"
    COB_IP_ADDR=${T//\"/}
    echo "COB_IP_ADDR = ${COB_IP_ADDR}"
    COB_IP_MASK=${U//\"/}
    echo "COB_IP_MASK = ${COB_IP_MASK}"
    COB_IP_GW=${V//\"/}
    echo "COB_IP_GW = ${COB_IP_GW}"
    COB_QIP=${W//\"/}
    echo "COB_QIP = ${COB_QIP}"
    QTREE=${X//\"/}
    echo "QTREE = ${QTREE}"
    BKUP_QIP=${Y//\"/}
    echo "BKUP_QIP = ${BKUP_QIP}"
    BKUP_IP_ADDR=${Z//\"/}
    echo "BKUP_IP_ADDR = ${BKUP_IP_ADDR}"
    BKUP_IP_MASK=${AA//\"/}
    echo "BKUP_IP_MASK = ${BKUP_IP_MASK}"
    BKUP_IP_GW=${AB//\"/}
    echo "BKUP_IP_GW = ${BKUP_IP_GW}"
    SEC_STYLE=${AC//\"/}
    echo "SEC_STYLE = ${SEC_STYLE}"
    #echo "Variables inside the Filesystem loop"
    #echo "${PROD_UNITY} | ${SP} | ${NAS_SERVER} | ${FS} | ${FS_SIZE} | ${FS_TYPE} | ${IP_ADDR} | ${IP_MASK} | ${IP_GW} |${COB_UNITY}"
    if [ "$CURRENT_NAS_SERVER" == "$NAS_SERVER" ]; then
        # No need to go get its ID, since we already have it in the loop
        LOG_MSG="Already have NAS Server ID for '${NAS_SERVER}': '${CURRENT_NAS_SERVER_ID}'"
        log "${LOG_MSG}"
    else
        CURRENT_NAS_SERVER=${NAS_SERVER}
        # The current NAS Server doesn't match this row, so we'll need to query
    	CURRENT_NAS_SERVER_ID=$(get_nas_server_id "${PROD_UNITY}" "${NAS_SERVER}")
        if [ $? -eq 0 ]; then
            LOG_MSG="Found NAS Server for '${NAS_SERVER}': '${CURRENT_NAS_SERVER_ID}'"
            log "${LOG_MSG}"
        else
            LOG_MSG="Could not get ID for NAS Server '${NAS_SERVER}'.  Does it exist?"
            log "${LOG_MSG}" "${LOG_ERR}"
        fi
    fi
    # var test
    #echo "${PROD_UNITY} | ${FS} | ${CURRENT_NAS_SERVER_ID} | ${POOL} | ${FS_SIZE} | ${SEC_STYLE}"
    # Filesystem creation
    RESULT=$(fs_create "${PROD_UNITY}" "${FS}" "${CURRENT_NAS_SERVER_ID}" "${POOL}" "${FS_SIZE}" "${SEC_STYLE}")

done < $INFILE
