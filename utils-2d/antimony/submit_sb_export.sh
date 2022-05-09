#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

if ! [[ "$BINDIR" == "/"* ]]; then
	BINDIR=$PWD/$BINDIR
fi

HOST=${HOST-$(hostname | cut -d'.' -f1)}

LOGDIR=$BINDIR/logs/export/$HOST
mkdir -p $LOGDIR

nattempts=$(ls $LOGDIR | wc -l)
mkdir -p $LOGDIR/$nattempts

NPARALLEL=${NPARALLEL-1}
array_size=$(cat $BINDIR/common_files/current_databases.txt | grep $HOST | wc -l)

export BINDIR

sbatch --array=1-$array_size%$NPARALLEL -o ${LOGDIR}/${nattempts}/%a.out -w $HOST -J sb_export $BINDIR/run_sb_export.sh
cat $BINDIR/common_files/current_databases.txt | grep $HOST | awk '{print $0 " " NR}' > $LOGDIR/$nattempts/portinfo

