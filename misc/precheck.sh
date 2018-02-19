#!/bin/bash

# Try to automate most of the validation for
# for migrations.

# break each piece out into individual functions

PATH=$PATH:/nas/bin:/nas/sbin:/usr/sbin
export PATH
LOGDIR="~"
DISKFULL=95
LOGFILE="`date +%Y-%m-%d-%T`_precheck.log"
# Change LOGLAST to something meaningful
LOGLAST="$1.last"
declare -A MSGTYPE
MSGTYPE[0]="INFO"
MSGTYPE[1]="WARN"
MSGTYPE[2]="ERROR"

# Logger function
logger()
{
	# If the disk utilization is less than $DISKFULL we append
	# Always write the last log message to the $LOGLAST file
	DISKUTIL=`df -k $LOGDIR|awk 'NR>1{print $5}'|sed 's/\%//'`
	if [ $DISKUTIL -lt $DISKFULL ]; then
		STAMP=`date +%Y-%m-%d - %T`
		echo $STAMP: ${MSGTYPE[$N]} - $LOGMSG >> $LOGDIR/$LOGFILE
	fi
	echo $STAMP: $LOGMSG > $LOGDIR/$LOGLAST
}

vdm_check()
{
# Check if its loaded
# Cifs server created, joined
}

int_check()
{

}

fs_check()
{
# check for rw/ro
# check space utilization
}
