#!/bin/bash
# utils-2d/patch_joblet_no_slurm.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
port=$1
source $BINDIR/../py36_psycopg2/bin/activate

set -e
(
	flock -x 9
	python $BINDIR/../2dload_new.py $port
) 9> /var/lock/2dload_new_patch_job.lock
