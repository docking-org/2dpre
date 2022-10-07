#!/bin/bash

export_type=$1
export_dest=$2
upload_requ=$3

HOST=$(hostname | cut -d'.' -f1)

cd $BINDIR

PORT=$(grep $HOST common_files/current_databases.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | cut -d':' -f2)
cd 2dload

upload_done=$(psql -h $HOST -p $PORT -d tin -U tinuser --csv -c "select ivalue from meta where varname = 'upload_name' and svalue = '$upload_requ'" | wc -l)

if ! [ $upload_done -eq 2 ]; then
	echo "required upload has not completed!"
	exit 1
fi

source py36_psycopg2/bin/activate
python 2dload.py $PORT tin export $export_type $export_dest
