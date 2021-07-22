#!/bin/bash
joblist=$1
bindir=$2

id=$SLURM_ARRAY_TASK_ID

port_args=$(head -n $id $joblist | tail -n 1)

port=$(echo $port_args | awk '{print $1}')
args=$(echo $port_args | awk '{$1=""; print $0}')

source $bindir/../py36_psycopg2/bin/activate

python $bindir/../2dload_new.py $port $args
