#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

exclude_nodes=${EXCLUDE_NODES-""}
for machine in $(cat $BINDIR/common_files/current_antimony_databases.txt | awk '{print $1}' | sort -u); do

	r=$(echo "$exclude_nodes" | grep $machine)
	if ! [ -z "$r" ]; then
		continue
	fi
	echo $machine
	export HOST=$machine
	bash $BINDIR/submit_sb_upload.sh

done
