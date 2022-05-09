#!/bin/bash
# utils-2d/runjob_2dload_new.bash
joblist=$1
bindir=$2

id=$SLURM_ARRAY_TASK_ID
host=$(hostname | cut -d'.' -f1)

port_args=$(grep $host $joblist | head -n $id | tail -n 1)

port=$(echo $port_args | awk '{print $2}')
args=$(echo $port_args | awk '{$1=""; $2=""; print $0}')

echo $port $args

cd $bindir/2dload
source py36_psycopg2/bin/activate

eval python 2dload.py $port $args
