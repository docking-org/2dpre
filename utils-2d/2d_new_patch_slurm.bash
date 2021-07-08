#!/bin/bash

if [ -z $BINDIR ]; then
	BINDIR=$(dirname $0)
	BINDIR=${BINDIR-.}

	if ! [[ "$BINDIR" == /* ]]; then
		BINDIR=$PWD/$BINDIR
	fi
fi
export BINDIR

HOST=$(hostname | cut -d'.' -f1)
for partition in /local2/load/H??????_H??????; do

	PORT=$(cat $partition/.port)
	sbatch -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-$PORT-%j.out -w $HOST -J 2dpatch $BINDIR/runcmd_2dload_new.bash $PORT ""

done
