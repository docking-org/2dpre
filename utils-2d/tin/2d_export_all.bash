#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

export_type=$1
export_dest=$2

[ -d $export_dest ] || exit 1
[[ "substance vendor antimony" == *$export_type* ]] || exit 1

for machine in $(cat $BINDIR/common_files/machines.txt); do
	n_dbs=$(cat $BINDIR/common_files/current_databases.txt | grep $machine | wc -l)
	latest_upload=$(cat $BINDIR/common_files/tin_upload_history.txt | tail -n 1)
	log_dir=$BINDIR/slurmlogs/export/$export_type/$latest_upload/$machine
	mkdir -p $log_dir
	grep $machine $BINDIR/common_files/current_databases.txt | awk '{print $0 "\t" NR}' > $log_dir/joblist_map
	export BINDIR
	sbatch --cpus-per-task=5 -w $machine -o $log_dir/%a.out -J z22_snex_${export_type} --array=1-$n_dbs%1 $BINDIR/export_job.bash $export_type $export_dest
done
