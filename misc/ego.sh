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

INPUT=$1
OLDIFS=$IFS
IFS=,
LOGDIR=/home
LOGFILE="`date +%Y%m%d-%T`_ego-provisioner.log"

# Check if user is root
if [[ $(id -u) -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi


POOL=`nas_pool -query:IsInUse==True,Status=ok,IsPoolBased=True -Format:'%s' -Fields:Name`

# Logging function defined, must fill $LOGMSG before executing
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

################################################################
# The if statements in both iptables functions need to be
# modified.  The status checks are pseudo, need to make the
# if statements check the actual results of the commands
################################################################
iptables_stop() {
	STATUS=`/sbin/service/iptables status`
	if [[ $STATUS == 'Running' ]]; then
		LOGMSG="iptables is running.  Attempting to stop"
		$(logger)
		RES=`/sbin/service iptables stop`
		if [[ $RES == 0 ]]; then
			LOGMSG="iptables has been stopped"
			$(logger)
		else
			LOGMSG="Could not stop iptables"
			$(logger)
		fi
	elif [[ $STATUS == 'Stopped' ]]; then
		LOGMSG="iptables is not running."
		$(logger)
	fi
}

iptables_start() {
	STATUS=`/sbin/service/iptables status`
	if [[ $STATUS == 'Stopped' ]]; then
		LOGMSG="iptables is stopped. Attempting to start"
		$(logger)
		RES=`/sbin/service iptables start`
		if [[ $RES == 0 ]]; then
			LOGMSG="iptables has been started"
			$(logger)
		else
			LOGMSG="Could not start iptables"
			$(logger)
		fi
	elif [[ $STATUS == 'Started' ]]; then
		LOGMSG="iptables is already running. Will not attempt to start"
		$(logger)
	fi
}

vdm_create() {
	if [[ $VDM == $(nas_server -query:Name==$VDM) ]]; then
		LOGMSG="VDM with name '$VDM' already exists"
		$(logger)
	else
		RES=`nas_server -name $VDM -type vdm -create $DM -setstate loaded pool=$POOL`
	fi
}

src_cs_pass() {

}















# Reset the original
IFS=$OLDIFS
