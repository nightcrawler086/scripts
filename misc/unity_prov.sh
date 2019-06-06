#!/bin/bash

# Input File
FILE=$1
# Datestamp
STAMP=$(date +%Y-$m-%d)
# Log file
OUTFILE="${STAMP}_unity-prov-log.txt"
# Define other log levels in their own variables
# so I don't have to reset the level each time
LOG_ERR="ERROR"
LOG_WRN="WARN"
# Check if the input file exists
[ ! -f $FILE ] && { echo "$FILE file not found"; exit 99; }

# Variables required:
# POOL Name or ID
# SP
# Server Name
# Username ?
# Password ?
#
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
# 10. Create NAS Server (COB)
# 11. Delete default NFS server (COB)
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

function log () {
    local MESSAGE=$1
    local LOGFILE=$OUTFILE
    local LEVEL=${2:-INFO}
    local STAMP=$(date "+%Y-%m-%d %H:%M:%S")
    local LINE="${STAMP} | ${LEVEL} | ${MESSAGE}"
    echo ${LINE} | tee "${LOGFILE}"
}
# Create the CIFS NAS Server
function nas_server_create_cifs () {
    local NAME=$1
    local SP=$2
    local POOL=$3
    # Get existing pool ID
    POOLID=$(uemcli -noHeader -sslPolicy accept /stor/config/pool -name ${POOL} show | grep 'ID\s\+\=' | awk -F'=' '{print $2}' | sed 's/^ *//g')
    # Create the server
    NAS_CREATE_RESULT=$(uemcli -noHeader -sslPolicy accept -u <USER> -p
    <PASSWORD> /net/nas/server create -name ${NAME} -sp ${SP} -pool ${POOLID}
    -enablePacketReflect yes)
    if [ $? -eq 0 ]; then
         LOG_MSG="NAS Server ${NAME} created successfully"
         log ${LOG_MSG} 
    else
        LOG_MSG="NAS Server ${NAME} failed to create with the following error"
        log "${LOG_MSG}" "${LOG_ERR}"
        log "${NAS_CREATE_RESULT}" "${LOG_ERR}"
        return 1
    fi
    # Filter out the server ID from the creation result
    # There seems to be an ID for each object, and a internal server ID
    # the internal server ID gets returned when the server is created, so we
    # can use that and save us from running another query.
    NAS_SERVER=$(grep 'ID\s\+\=' <<< ${NAS_CREATE_RESULT} | awk -F'=' '{print $2}' | sed 's/^ *//g')
    # Delete NFS server that got created with it
    NFS_SERVER_DEL_RESULT=$(uemcli -noHeader -sslPolicy accept -u <USER> -p <PASSWORD> /net/nas/nfs
    -server ${NAS_SERVER} delete)
}
function nas_server_int_create () {
    local IP_ADDR=$1
    local IP_NETMASK=$2
    local IP_GW=$3
    local SP=$4
    local NAS_SERVER_NAME=$5
    FSN_DEVICES=$(uemcli -noHeader -sslPolicy accept /net/fsn show -output csv
    -filter "SP,ID")
    FSN=$(awk -F, -v q='"' '$1 == q"${SP}"q {print $2}' <<< $(echo ${FSN_DEVICES}))


}
