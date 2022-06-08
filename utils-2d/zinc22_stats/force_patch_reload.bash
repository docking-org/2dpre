#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

patch=$1

for d in $(cat $BINDIR/common_files/current_databases.txt); do

	host=$(echo $d | cut -d':' -f1)
	port=$(echo $d | cut -d':' -f2)
	echo $host:$port
	psql -h $host -p $port -d tin -U tinuser -c "update patches set patched=false where patchname='$patch'"

done
