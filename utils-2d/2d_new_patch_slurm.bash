#!/bin/bash

if [ -z $BINDIR ]; then
	BINDIR=$(dirname $0)
	BINDIR=${BINDIR-.}

	if ! [[ "$BINDIR" == /* ]]; then
		BINDIR=$PWD/$BINDIR
	fi
fi
export BINDIR

NPARALLEL=${NPARALLEL-2}
HOST=$(hostname | cut -d'.' -f1)

joblist_name="/local2/load/2d_patch_$(date +%s)_joblist.txt"

printf "" > $joblist_name

for partition in /local2/load/H??????_H??????; do

	PORT=$(cat $partition/.port)
	echo $PORT >> $joblist_name
	#sbatch -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-$PORT-%j.out -w $HOST -J 2dpatch $BINDIR/runcmd_2dload_new.bash $PORT ""

done

njobs=$(cat $joblist_name | wc -l)

sbatch -a 1-$njobs%$NPARALLEL -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-$PORT-%A-%a.out -w $HOST -J 2dpatch $BINDIR/runjob_2dload_new.bash $joblist_name $BINDIR
