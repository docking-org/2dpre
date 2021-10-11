#!/bin/bash
# utils-2d/patch_job_no_slurm.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

source $BINDIR/../py36_psycopg2/bin/activate
host=$(hostname | cut -d'.' -f1)
logdir=/tmp/psql_$host
if ! [ -d $logdir ]; then
	mkdir -p $logdir
fi

ports=$1

if [ -z "$ports" ]; then
	ports="$(cat /local2/load/H*/.port)"
fi

for p in $ports; do
	bash $BINDIR/patch_joblet_no_slurm.bash $p > ${logdir}/2dpatch_noslurm_$p.out 2>&1 &
	#python $BINDIR/../2dload_new.py $p > ${logdir}/2dpatch_noslurm_$p.out 2>&1 &
done
