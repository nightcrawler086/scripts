#!/bin/bash

# Checking if number of subdirectories exceeds a certain limit
# for EACH directory in a tree

SUBDIRMAX=65533

find . -type d -print0 | while read -d '' -r DIR; do
	SUBDIRS=$(find "$DIR" -type d -maxdepth 1 | wc -l)
	if (( $SUBDIRS > $SUBDIRMAX )); then
		printf "\"%s\" contains %d subdirectories\n" "$DIR" "$SUBDIRS"
	fi
done

