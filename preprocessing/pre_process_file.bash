#!/bin/bash
# in: INPUT_FILE, OUTPUT_DEST, BINPATH, CATALOG

STAGE_DIR=/nfs/exb/zinc22/2dpre_staging/$CATALOG/$(basename $INPUT_FILE)

mkdir -p $STAGE_DIR
mkdir -p $STAGE_DIR/in
mkdir -p $STAGE_DIR/out
mkdir -p $STAGE_DIR/log


# avoid splitting input if it already has been split prior
if ! [ -f $STAGE_DIR/jobs_all.txt ]; then
	length=$(cat $INPUT_FILE | wc -l)
	echo "length of input file: $length" 1>&2
	nlines=20000
	while [ $((length/nlines)) -gt 250 ]; do
		nlines=$((nlines+1000))
	done
	echo "splitting input file into chunks of $nlines @ $STAGE_DIR/in" 1>&2
	split --suffix-length=3 --lines=$nlines $INPUT_FILE $STAGE_DIR/in/
fi

find $STAGE_DIR/out -size 0 | xargs rm 2>/dev/null

pushd $STAGE_DIR/out
find . -type f | sort > $STAGE_DIR/jobs_cmp.txt
pushd $STAGE_DIR/in
find . -type f  | sort > $STAGE_DIR/jobs_all.txt
popd
popd

sort $STAGE_DIR/jobs_cmp.txt $STAGE_DIR/jobs_all.txt | uniq -u | awk -v s=$STAGE_DIR/in '{print s"/"$0}' > $STAGE_DIR/jobs_now.txt
ntasks=$(cat $STAGE_DIR/jobs_now.txt | wc -l)

if [ $ntasks -eq 0 ]; then
	echo $INPUT_FILE already complete! 1>&2
	# this logic moved to combine_all_files.bash
	#if ! [ -f $OUTPUT_DEST ]; then
	#	echo "detected completion of processing, but not combination of files, submitting combine job" 1>&2
	#	comb_jobid=$(sbatch --priority=1000000 --parsable -o /dev/null -J sn_pre_comb --priority="TOP" $BINPATH/combine_files.bash $STAGE_DIR/out $OUTPUT_DEST)
	#	echo "combine=$comb_jobid" 1>&2
	#fi
	exit 0
fi

export STAGE_DIR
export SOURCE=$STAGE_DIR/jobs_now.txt
export DEST=$STAGE_DIR/out
export BINPATH
echo "submitting $ntasks preprocessing jobs..." 1>&2
jobid=$(sbatch --mem-per-cpu=2G -o "$STAGE_DIR/log/%a.out" -e "$STAGE_DIR/log/%a.err" -J sn_pre --cpus-per-task=2 --parsable --array=1-$ntasks --priority=9999 $BINPATH/pre_process.bash)
#comb_jobid=$(sbatch --priority=1000000 --parsable -o /dev/null -J sn_pre_comb --priority="TOP" --dependency=afterok:$jobid $BINPATH/combine_files.bash $STAGE_DIR/out $OUTPUT_DEST)

#echo $comb_jobid
