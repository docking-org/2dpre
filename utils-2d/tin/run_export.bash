#!/bin/bash
BINDIR=${BINDIR-$(dirname $0)}
BINDIR=${BINDIR-.}

target_dir=$1
host=$(hostname | cut -d'.' -f1)
thisport=$(grep $host $BINDIR/common_files/current_databases.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | cut -d':' -f2)
thispartition=$(grep $host $BINDIR/common_files/database_partitions.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 | awk '{print $2}')
echo $thisport $thispartition
thisstarttranche=$(grep -w $thispartition $BINDIR/common_files/partitions.txt | awk '{print $1}')

hac=$(echo $thisstarttranche | awk '{print substr($1, 1, 3)}')

if [ -e $target_dir/$hac/$thisstarttranche.smi.gz ]; then
	echo "database is already exported, exiting"
	echo "delete exported files to avoid this message"
	exit
fi

export REQUIRED_UPLOAD
$BINDIR/export.bash $target_dir $thisport
