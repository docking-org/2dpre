#!/bin/bash
# in: TRANCHES, PARTITION_ID, CATALOG_SHORTNAME

function wait_for_preprocess_space {
        njobs=$(squeue -u $(whoami) --array | grep pre | wc -l)
        first=
        while [ $njobs -gt 1000 ]; do
                [ -z $first ] && echo "waiting for space to free up in queue"
                sleep 10
                njobs=$(squeue --array | grep pre | wc -l)
                first=f
        done
}

PARTITION_ID=$1
TRANCHES=$2
CATALOG=$3
EXPORT_DEST=${EXPORT_DEST-/nfs/exb/zinc22/2dpre_results/$CATALOG}

BINPATH=$(dirname $0)
BINPATH=${BINPATH-.}
pushd $BINPATH
BINPATH=$PWD
popd

export BINPATH
export CATALOG

mkdir -p $EXPORT_DEST
EXPORT_DEST=$EXPORT_DEST
p_start=$(grep -w $PARTITION_ID $BINPATH/partitions.txt | awk '{print $1}')
p_end=$(grep -w $PARTITION_ID $BINPATH/partitions.txt | awk '{print $2}')
tranche_files=$(python $BINPATH/get_partition_tranche_files.py $TRANCHES $p_start $p_end)

for tranche_file in $tranche_files; do

    if [[ $tranche_file == MISSING* ]]; then
        TRANCHE_NAME=$(printf $tranche_file | cut -d':' -f2)
	TRANCHE_HAC=$(echo $TRANCHE_NAME | awk '{print substr($1, 1, 3)}')
        echo $TRANCHE_NAME missing from tranches, no worries
	
	mkdir -p $EXPORT_DEST/$TRANCHE_HAC
        touch $EXPORT_DEST/$TRANCHE_HAC/${TRANCHE_NAME}.smi
	continue
    fi

    TRANCHE_NAME=$(basename $tranche_file | cut -d'.' -f1)
    TRANCHE_HAC=$(echo $TRANCHE_NAME | awk '{print substr($1, 1, 3)}')
    export INPUT_FILE=$tranche_file
    export OUTPUT_DEST=$EXPORT_DEST/$TRANCHE_HAC/${TRANCHE_NAME}.smi
    mkdir -p $(dirname $OUTPUT_DEST)

    if [ -f $OUTPUT_DEST ]; then
        echo $OUTPUT_DEST already exists 
        continue
    fi

    echo $INPUT_FILE $OUTPUT_DEST $CATALOG 
    jobid=$($BINPATH/pre_process_file.bash)

    JOBS_TO_WAIT_ON="$JOBS_TO_WAIT_ON $jobid"
    TRANCHES_TO_ADD="$TRANCHES_TO_ADD $TRANCHE_NAME"
   
    wait_for_preprocess_space 
done

echo $JOBS_TO_WAIT_ON
echo $TRANCHES_TO_ADD

jobdep=$(echo $JOBS_TO_WAIT_ON | tr ' ' ':')
