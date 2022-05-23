#!/bin/bash

export_type=$1
export_dest=$2

HOST=$(hostname | cut -d'.' -f1)

cd $BINDIR

PORT=$(grep $HOST common_files/current_databases.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | cut -d':' -f2)
cd 2dload

source py36_psycopg2/bin/activate
python 2dload.py $PORT tin export $export_type $export_dest
