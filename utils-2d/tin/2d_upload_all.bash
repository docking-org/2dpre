#!/bin/bash

if [ -z $BINDIR ]; then
        BINDIR=$(dirname $0)
        BINDIR=${BINDIR-.}

        if ! [[ "$BINDIR" == /* ]]; then
                BINDIR=$PWD/$BINDIR
        fi
fi
export BINDIR
export UPLOAD_TYPE
export JUST_UPDATE_INFO

source_dirs=$1
catalogs=$2
diff_destination=$3

for machine in $(cat $BINDIR/common_files/machines.txt); do

	export HOST=$machine
	$BINDIR/2d_upload_slurm.bash $source_dirs $catalogs $diff_destination
	#sbatch -o $machine.upload_all.slurmlog -w $machine $BINDIR/2d_upload_slurm.bash "$catalogs"

done
