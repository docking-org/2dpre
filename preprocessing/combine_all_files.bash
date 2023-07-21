#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi	

catalog=$1

MAX_PARALLEL=25

STAGE_DIR=/nfs/exb/zinc22/2dpre_staging/$catalog

for src in $(find $STAGE_DIR -maxdepth 1 -type d -name '*.smi' | awk '{print $0"/out"}' | sort); do
	tranche=$(basename $(dirname $src) | cut -d'.' -f1)
	hac=$(echo $tranche | awk '{print substr($1, 1, 3)}')
	dst=/nfs/exb/zinc22/2dpre_results/$catalog/$hac/${tranche}.smi
	[ -f $dst ] && echo $dst already exists! 1>&2 && continue
	echo $src $dst 1>&2
	echo $src $dst
done > $STAGE_DIR/all_out_directories.txt
num_out_directories=$(cat $STAGE_DIR/all_out_directories.txt | wc -l)

echo going to submit $num_out_directories combine jobs!
echo limiting to $MAX_PARALLEL at once

mkdir $STAGE_DIR/combine_logs 
sbatch --array=1-${num_out_directories}%$MAX_PARALLEL -o $STAGE_DIR/combine_logs/%a.out $BINDIR/combine_files.bash $STAGE_DIR/all_out_directories.txt
