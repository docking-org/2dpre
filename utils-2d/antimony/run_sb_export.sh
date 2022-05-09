#! /bin/bash
# req: BINDIR

HOST=$(hostname | cut -d'.' -f1)
port=$(cat $BINDIR/common_files/current_databases.txt | grep $HOST | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | cut -d':' -f2)

# cd into the base directory for 2dload.py, bc i dont know how to get a python program structure to work outside of it
cd $BINDIR/2dload
source py36_psycopg2/bin/activate
python 2dload.py $port tin export_antimony
