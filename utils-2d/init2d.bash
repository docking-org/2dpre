#!/bin/bash
# desc: creates a blank partition database

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

partition_id=$1

start_end=$(grep -w $partition_id $BINDIR/partitions.txt | awk '{print $1 " " $2}')
label=$(printf "$start_end" | tr ' ' '_')

python $BINDIR/get_partition_tranche_files.py NONE $start_end | xargs -n 1 -I {} mkdir -p /local2/load/$label/src/{}
