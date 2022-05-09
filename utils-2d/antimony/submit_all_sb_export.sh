#!/bin/bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

if ! [[ "$BINDIR" == "/"* ]]; then
	BINDIR=$PWD/$BINDIR
fi

for machine in $(cat $BINDIR/common_files/machines.txt); do

	echo $machine
	export HOST=$machine
	bash $BINDIR/submit_sb_export.sh

	#nprev=$(ls $BINDIR/logs/submit | grep $machine | cut -d'.' -f2 | sort -k2n | tail -n 1)
	#nprev=${nprev-0}
	#$BINDIR/submit_sb_export.sh
	#sbatch -w $machine -o $BINDIR/logs/submit/$machine.$nprev.out --priority=9999999 $BINDIR/submit_sb_export.sh

done
