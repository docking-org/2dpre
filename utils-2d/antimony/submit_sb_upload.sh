#! /bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

if ! [[ "$BINDIR" == "/"* ]]; then
        BINDIR=$PWD/$BINDIR
fi

NPARALLEL=${NPARALLEL-4}
HOST=${HOST-$( hostname | cut -d '.' -f1)}
LOGDIR=$BINDIR/logs/upload/$HOST

mkdir -p $LOGDIR

array_length=$(grep $HOST $BINDIR/common_files/current_antimony_databases.txt | wc -l)

nattempts=$(ls $LOGDIR | wc -l)
mkdir -p $LOGDIR/$nattempts

export BINDIR

sbatch $SBATCH_ARGS -c 5 -a 1-$array_length%$NPARALLEL -o ${LOGDIR}/${nattempts}/%a.out -w $HOST -J z22_sbup $BINDIR/run_sb_upload.sh

grep $HOST $BINDIR/common_files/current_antimony_databases.txt > $LOGDIR/$nattempts/portinfo
