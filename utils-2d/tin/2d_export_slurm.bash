#!/bin/bash
# utils-2d/tin/2d_export_slurm.bash

if [ -z $BINDIR ]; then
        BINDIR=$(dirname $0)
        BINDIR=${BINDIR-.}

        if ! [[ "$BINDIR" == /* ]]; then
                BINDIR=$PWD/$BINDIR
        fi
fi
export BINDIR

target_dir=$1
NPARALLEL=${NPARALLEL-4}
HOST=${HOST-$(hostname | cut -d'.' -f1)}

njobs=$(grep $HOST $BINDIR/common_files/current_databases.txt | wc -l)

export REQUIRED_UPLOAD
mkdir -p $BINDIR/slurmlogs/export/$HOST
PRIORITY=${PRIORITY-5000}

sbatch --priority $PRIORITY -c 5 -a 1-$njobs%$NPARALLEL -o $BINDIR/slurmlogs/export/$HOST/%A-%a.out -w $HOST -J 2dexport $BINDIR/run_export.bash $target_dir
