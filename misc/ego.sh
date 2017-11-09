#!/bin/bash

#################################################
# Script Name: ego.sh
#
# Purpose:
#
# Provisioning Script for NAS
#
# Usage:
#
# > ego.sh <INPUT_FILE>
#
# Author:  Brian Hall
# Date: Tue Nov 7 20:28:37 EST 2017
#################################################

if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

INPUT=$1
OLDIFS=$IFS
IFS=,
LOGDIR=/home

$POOL=`nas_pool -query:IsInUse==True,Status=ok,IsPoolBased=True -Format:'%s' -Fields:Name`

logger() {
	DISKCHK=`df -k $LOGDIR | awk 'NR>1{print $5}'| sed 's/\%//'`
	# if there's enough free disk space, append to log
	if [ $DISKCHK -lt $DISKFULL ]; then
		TDSTAMP=`date +%Y-%m-%d' '%T`
		echo $TDSTAMP: $LOGMSG | tee -a $LOGDIR/$LOGFILE
	fi
	# regardless of available space, always write last error echo
	$TDSTAMP: $LOGMSG > $LOGDIR/$LOGLAST
}

vdm_create() {
	if [[ nas_server -query:Name==$VDM ]]; then
		$LOGMSG
		$(logger)
	else

		RES=`nas_server -name $VDM -type vdm -create $DM -setstate loaded pool=$POOL`

	fi
}


















IFS=$OLDIFS
