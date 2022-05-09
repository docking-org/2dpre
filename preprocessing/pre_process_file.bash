#!/bin/bash
# in: INPUT_FILE, OUTPUT_DEST, BINPATH, CATALOG

STAGE_DIR=/nfs/exb/zinc22/2dpre_staging/$CATALOG/$(basename $INPUT_FILE)

mkdir -p $STAGE_DIR
mkdir -p $STAGE_DIR/in
mkdir -p $STAGE_DIR/out
mkdir -p $STAGE_DIR/log

echo "." 1>&2
length=$(cat $INPUT_FILE | wc -l)
echo "length of input file: $length" 1>&2
nlines=20000
while [ $((length/nlines)) -gt 1000 ]; do
	nlines=$((nlines+1000))
done
if [ $(ls $STAGE_DIR/in | wc -l) -gt 0 ]; then
	rm $STAGE_DIR/in/*
	echo "found and removed existing files from stage dir in" 1>&2
fi
if [ $(ls $STAGE_DIR/out | wc -l) -gt 0 ]; then
	rm  $STAGE_DIR/out/*
	echo "found and removed existing files from stage dir out" 1>&2
fi

echo "splitting input file into chunks of $nlines @ $STAGE_DIR/in" 1>&2
split --suffix-length=3 --lines=$nlines $INPUT_FILE $STAGE_DIR/in/
ntasks=$(ls $STAGE_DIR/in | wc -l)

export SOURCE=$STAGE_DIR/in
export DEST=$STAGE_DIR/out
export BINPATH
echo "submitting $ntasks preprocessing jobs..." 1>&2
jobid=$(sbatch  -o "$STAGE_DIR/log/%a.out" -e "$STAGE_DIR/log/%a.err" -J sn_pre --cpus-per-task=1 --parsable --array=1-$ntasks --priority=1000000 $BINPATH/pre_process.bash)
comb_jobid=$(sbatch --priority=1000000 --parsable -o /dev/null -J sn_pre_comb --priority="TOP" --dependency=afterok:$jobid $BINPATH/combine_files.bash $OUTPUT_DEST $DEST)
#cat $DEST/* > $OUTPUT_DEST
echo $comb_jobid
#echo "done! length of output file: $(cat $OUTPUT_DEST | wc -l)" 1>&2

#rm -r $STAGE_DIR
