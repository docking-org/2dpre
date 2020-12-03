#!/bin/bash
# in: TRANCHES, PARTITION_ID
PARTITION_ID=$1
TRANCHES=$2
EXPORT_DEST=${EXPORT_DEST-/local2/load}

BINPATH=$(dirname $0)
BINPATH=${BINPATH-.}
export BINPATH

mkdir -p $EXPORT_DEST/preprocessing
EXPORT_DEST=$EXPORT_DEST/preprocessing
p_start=$(grep -w $PARTITION_ID $BINPATH/partitions.txt | awk '{print $1}')
p_end=$(grep -w $PARTITION_ID $BINPATH/partitions.txt | awk '{print $2}')
tranche_files=$(python $BINPATH/get_partition_tranche_files.py $TRANCHES $p_start $p_end)
for tranche_file in $tranche_files; do
    echo $tranche_file
    TRANCHE_NAME=$(basename $tranche_file | cut -d'.' -f1)
    export INPUT_FILE=$tranche_file
    export OUTPUT_DEST=$EXPORT_DEST/$TRANCHE_NAME
    $BINPATH/pre_process_file.bash
    tar -C $EXPORT_DEST -rf $EXPORT_DEST/$PARTITION_ID.pre $TRANCHE_NAME
    
done
