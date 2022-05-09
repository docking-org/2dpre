#!/bin/bash

target_dir=$1

if [ -z $BINDIR ]; then
        BINDIR=$(dirname $0)
        BINDIR=${BINDIR-.}

        if ! [[ "$BINDIR" == /* ]]; then
                BINDIR=$PWD/$BINDIR
        fi
fi
export BINDIR
export REQUIRED_UPLOAD
for machine in $(cat $BINDIR/common_files/machines.txt); do

	export HOST=$machine
	$BINDIR/2d_export_slurm.bash $target_dir
        #sbatch -J 2dexp_all -o $BINDIR/slurmlogs/export/$machine.upload_all.slurmlog -w $machine $BINDIR/2d_export_slurm.bash $target_dir

done
