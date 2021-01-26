#!/bin/bash
imageid=$1

if [ -z $imageid ]; then
	echo "please provide an image id. exiting with error!"
	exit 1
fi

BINDIR=${BINDIR-.}
id=$SLURM_ARRAY_TASK_ID

jobinfo=$(sed "${id}q;d" /dev/shm/prejoblist_$imageid.txt)

$BINDIR/../preprocessing/pre_process_partition.bash $jobinfo
