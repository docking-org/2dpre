#!/bin/bash

BINPATH=$(dirname $0)
BINPATH=${BINPATH-.}
PARTITION_ID=$1
CATALOG_SHORT=$2
TRANCHES=$3

export PARTITION_ID
export TRANCHES

$BINPATH/preprocessing/pre_process_partition.bash

python $BINPATH/2dload.py add $PARTITION_ID /tmp/$PARTITION_ID.pre $CATALOG_SHORT