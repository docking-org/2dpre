#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

for machine in $(cat $BINDIR/common_files/current_antimony_databases.txt | awk '{print $1}' | sort -u); do

	echo $machine
	export HOST=$machine
	bash $BINDIR/submit_sb_upload.sh

done
