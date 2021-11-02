#!/bin/bash
# utils-2d/2d_new_patch_slurm.bash

if [ -z $BINDIR ]; then
	BINDIR=$(dirname $0)
	BINDIR=${BINDIR-.}

	if ! [[ "$BINDIR" == /* ]]; then
		BINDIR=$PWD/$BINDIR
	fi
fi
export BINDIR

catalogs=$1
ports=$2

NPARALLEL=${NPARALLEL-2}
HOST=$(hostname | cut -d'.' -f1)

joblist_name="/local2/load/2d_upload_$(date +%s)_joblist.txt"

printf "" > $joblist_name

while IFS= read -r entry; do

	echo "$entry"
	port=$(printf $entry | cut -d':' -f2)
	pno=$(printf "$entry" | awk '{print $2}')
	echo $port $pno
	if ! [ -z "$ports" ] && ! [[ "$ports" == *"$port"* ]]; then
		continue
	fi

	files=""
	for catalog in $catalogs; do

		file=/nfs/exb/zinc22/2dpre_results/$catalog/${pno}.pre
		if ! [ -f $file ]; then
			echo "$file cannot be found! generate this file and try again!"
			exit 1
		fi
		files="${files}$file "

	done
	files=$(printf "$files" | head -c -1) # trim off the last whitespace

	echo $port upload \""$files"\" \""$catalogs"\" >> $joblist_name

done <<< "$(grep $HOST $BINDIR/common_files/database_partitions.txt)"

njobs=$(cat $joblist_name | wc -l)

# each machine has 80 cores, so each job will reserve 1/4 of the machines cpu power, which should be more than enough
# this also means that other jobs will not interfere with the patching, while still allowing them some room
sbatch -c 20 -a 1-$njobs%$NPARALLEL -o /nfs/exb/zinc22/2dload_logs/psql_$HOST/%x-%A-%a.out -w $HOST -J 2dupload $BINDIR/runjob_2dload_new.bash $joblist_name $BINDIR
