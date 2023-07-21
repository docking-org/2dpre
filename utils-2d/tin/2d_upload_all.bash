#!/bin/bash

if [ -z $BINDIR ]; then
        BINDIR=$(dirname $0)
        BINDIR=${BINDIR-.}

        if ! [[ "$BINDIR" == /* ]]; then
                BINDIR=$PWD/$BINDIR
        fi
fi
export BINDIR
export JUST_UPDATE_INFO
export FAKE_UPLOAD

upload_type=$1
source_dirs=$2
catalogs=$3
diff_destination=$4

export UPLOAD_TYPE=$upload_type

TARGET_MACHINE=${TARGET_MACHINE-}

for machine in $(cat $BINDIR/common_files/machines.txt); do
	if ! [ -z $TARGET_MACHINE ] && ! [ $TARGET_MACHINE = $machine ]; then
		continue
	fi
	export HOST=$machine
	$BINDIR/2d_upload_slurm.bash "$source_dirs" "$catalogs" $diff_destination
	#sbatch -o $machine.upload_all.slurmlog -w $machine $BINDIR/2d_upload_slurm.bash "$catalogs"

done
