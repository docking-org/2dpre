#!/bin/bash
# utils-2d/rebuild_pre_files.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

partition_nos=$@

for p in $partition_nos; do

	pstart=$(cat $BINDIR/common_files/partitions.txt | grep -w $p | awk '{print $1}')
	pend=$(cat $BINDIR/common_files/partitions.txt | grep -w $p | awk '{print $2}')
	echo $(date) :::: $p $pstart $pend

	bdir=/nfs/exb/zinc22/2dpre_results
	tranches=$(python $BINDIR/get_partition_tranche_files.py NONE $pstart $pend)
	for cat in $(cat $BINDIR/common_files/catalogs.txt); do
		echo $(date) :::: $cat

		tar -C $bdir/$cat -czf $bdir/$p.pre.test $tranches
		code=$!
		if [ $code -eq 0 ]; then
			printf ""
			#mv $bdir/$p.pre.test $bdir/$p.pre
		fi
	done
done
