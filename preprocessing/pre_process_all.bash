#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
tranches=$1
catalog=$2

function wait_for_preprocess_space {
	njobs=$(squeue -u $(whoami) --array | grep pre | wc -l)
        first=
        while [ $njobs -gt 500 ]; do
                [ -z $first ] && echo "waiting for space to free up in queue"
                sleep 10
                njobs=$(squeue --array | grep pre | wc -l)
                first=f
        done
}

for pid in $(awk '{print $2}' $BINDIR/database_partitions.txt); do

	bash $BINDIR/pre_process_partition.bash $pid $tranches $catalog
	wait_for_preprocess_space
	! [ -z $first ] && echo "found space, submitting more!"

done
