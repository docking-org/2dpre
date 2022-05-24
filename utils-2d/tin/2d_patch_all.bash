#!/bin/bash

if [ -z $BINDIR ]; then
        BINDIR=$(dirname $0)
        BINDIR=${BINDIR-.}

        if ! [[ "$BINDIR" == /* ]]; then
                BINDIR=$PWD/$BINDIR
        fi
fi
export BINDIR

catalogs=$1

for machine in $(cat $BINDIR/common_files/machines.txt); do

	$BINDIR/2d_patch_slurm.bash

done
