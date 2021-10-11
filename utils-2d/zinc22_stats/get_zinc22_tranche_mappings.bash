#!/bin/bash
# utils-2d/zinc22_stats/get_zinc22_tranche_mappings.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

pwfile=$1
output=$BINDIR/statistics/tranche_mappings/tranche_mappings_$(date "+%m_%d_%Y").txt

if [ -f $output ]; then
	printf "" > $output
fi

for m in $(cat $BINDIR/machines.txt); do

	echo $m
	data=$(sshpass -p password ssh $(whoami)@$m exec 'head /local2/load/H*/.port' | sed 's/<//g; s/>//g; s/ //g; s/.*\(H[0-9]\{2\}\(P\|M\)[0-9]\{3\}_H[0-9]\{2\}\(P\|M\)[0-9]\{3\}\).*/\1/g' | sed 's/\(^[0-9]\+\)$/:\1,/g' | tr --delete '\n' | head -c -1)
	echo $data
	for partitionpair in $(echo $data | tr ',' '\n'); do
		partition=$(echo $partitionpair | cut -d':' -f1)
		port=$(echo $partitionpair | cut -d':' -f2)
		pstart=$(echo $partition | cut -d'_' -f1)
		pfinsh=$(echo $partition | cut -d'_' -f2)
		echo $partition $port $pstart $pfinish
		for tranche in $(python $BINDIR/get_partition_tranche_files.py NONE $pstart $pfinsh); do
			echo $tranche:$m:$port >> $output
		done
	done

done

sort $output > $output.t
mv $output.t $output
