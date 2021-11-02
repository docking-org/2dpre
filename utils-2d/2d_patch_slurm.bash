#!/bin/bash
# utils-2d/2d_new_patch_slurm.bash

if [ -z $BINDIR ]; then
	BINDIR=$(dirname $0)
	BINDIR=${BINDIR-.}

	if ! [[ "$BINDIR" == /* ]]; then
		BINDIR=$PWD/$BINDIR
	fi
fi
export BINDIR

ports=$1
NPARALLEL=${NPARALLEL-2}
HOST=$(hostname | cut -d'.' -f1)


joblist_name="/local2/load/2d_patch_$(date +%s)_joblist.txt"

printf "" > $joblist_name

for partition in /local2/load/H??????_H??????; do

	PORT=$(cat $partition/.port)

	if ! [ -z "$ports" ] && ! [[ "$ports" == *"$PORT"* ]]; then
                continue
        fi

	echo $PORT

	echo $PORT >> $joblist_name
	#sbatch -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-$PORT-%j.out -w $HOST -J 2dpatch $BINDIR/runcmd_2dload_new.bash $PORT ""

done

njobs=$(cat $joblist_name | wc -l)

# each machine has 80 cores, so each job will reserve 1/4 of the machines cpu power, which should be more than enough
# this also means that other jobs will not interfere with the patching, while still allowing them some room
sbatch -c 20 -a 1-$njobs%$NPARALLEL -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-%A-%a.out -w $HOST -J 2dpatch $BINDIR/runjob_2dload_new.bash $joblist_name $BINDIR
