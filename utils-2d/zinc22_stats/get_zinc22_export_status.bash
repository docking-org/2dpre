#!/bin/bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

export_dir=$1

for d in $(cat $BINDIR/common_files/database_partitions.txt | tr ' ' ':'); do
	host=$(echo $d | cut -d':' -f1)
	port=$(echo $d | cut -d':' -f2)
	part=$(echo $d | cut -d':' -f3)

	part_start=$(grep -w $part $BINDIR/common_files/partitions.txt | awk '{print $1}')
	part_finsh=$(grep -w $part $BINDIR/common_files/partitions.txt | awk '{print $2}')
	suc=0
	tot=0
	for tranche in $(python3 get_partition_tranche_files.py NONE $part_start $part_finsh); do
		tot=$((tot+1))
		hac=$(echo $tranche | awk '{print substr($1, 1, 3)}')
		target=$export_dir/$hac/${tranche}.smi
		target2=$export_dir/${tranche}
		if [ -z $CHECK_EMPTY ]; then
			if [ -f $target ] || [ -f $target.gz ] || [ -f $target2 ]; then
				suc=$((suc+1))
			fi
		else
			if [ -s $target ] || [ -s $target.gz ] || [ -s $target2 ]; then
				suc=$((suc+1))
			fi
		fi
	done
	result="$suc/$tot"

	echo $host:$port::$part_start"->"$part_finsh::$result
done
