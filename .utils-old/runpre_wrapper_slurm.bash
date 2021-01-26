#!/bin/bash

BINDIR=${BINDIR-.}
id=$SLURM_ARRAY_TASK_ID

jobinfo=$(sed "${id}q;d" /dev/shm/prejoblist.txt)

$BINDIR/../preprocessing/pre_process_partition.bash $jobinfo
#$BINDIR/../preprocessing/run_partition_load.bash $jobinfo
