#!/bin/bash

echo -n "Enter the command and press [ENTER]:"
read cmd
divider===============================
divider=$divider$divider
header="\n %-30s %-17s %-11s\n"
format=" %-30s %-17s %-11s\n"
width=57

printf "Testing hosts found in export statement for <vFiler>:<path>"
printf "$header" "HOSTNAME" "IP Address" "Status"
printf "%$width.${width}s\n" "$divider"

var=$(showmount --no-headers -e <vFiler> | grep <volume> | cut -d ' ' -f <field>)
IFS=',' read -ra HOSTS <<< $var

for h in "${HOSTS[@]}"; do
	ping -c 2 $h > /dev/null
	if [[ $? == 0 ]]; then
		status="Alive"
		hostname=$(getent hosts $h | awk '{print $2}')
		IP=$(getent hosts $h | awk '{print $1}')
	else
		status="Not Alive"
		hostname=$h
		IP="Not Found"
	fi
printf "$format" \
	"$(echo $hostname)" \
	"$(echo $IP)" \
	"$status"
done
