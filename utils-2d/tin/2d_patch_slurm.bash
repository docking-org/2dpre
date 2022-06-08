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
NPARALLEL=${NPARALLEL-1}
HOST=${HOST-$(hostname | cut -d'.' -f1)}


mkdir -p $BINDIR/slurmlogs/patch
nattempts=$(ls $BINDIR/slurmlogs/patch | wc -l)
logdir=$BINDIR/slurmlogs/patch/$nattempts
mkdir $logdir
joblist_name="$logdir/joblist.txt"

printf "" > $joblist_name

if [ -z "$ports" ]; then
	for hostport in $(cat $BINDIR/common_files/current_databases.txt | grep $m); do

		host=$(echo $hostport | cut -d':' -f1)
		port=$(echo $hostport | cut -d':' -f2)
		#PORT=$(cat $partition/.port)

		#if ! [ -z "$ports" ] && ! [[ "$ports" == *"$PORT"* ]]; then
		#	continue
		#fi

		#echo $PORT

		echo $HOST $port tin patch >> $joblist_name

	done
else
	echo "$ports" | tr ' ' '\n' > $joblist_name
fi


njobs=$(grep $m $BINDIR/common_files/current_databases.txt | wc -l)

mkdir $logdir/$m
sbatch -c 20 -a 1-$njobs%$NPARALLEL -o $logdir/$m/%a.out -w $m -J 2dpatch $BINDIR/runjob_2dload_new.bash $joblist_name $BINDIR
