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

source_dirs=$1
catalogs=$2
diff_destination=$3
#ports=$2

uploadtype=${UPLOAD_TYPE-upload}
justupdate=${JUST_UPDATE_INFO-}

NPARALLEL=${NPARALLEL-1}
HOST=${HOST-$(hostname | cut -d'.' -f1)}

mkdir -p $BINDIR/slurmlogs/$uploadtype/$HOST
nattempts=$(ls $BINDIR/slurmlogs/$uploadtype/$HOST | wc -l)
logdir=$BINDIR/slurmlogs/$uploadtype/$HOST/$nattempts
mkdir -p $logdir
joblist_name="$logdir/joblist.txt"

printf "" > $joblist_name

if ! [ -z "$FAKE_UPLOAD" ]; then
	extra_args="$extra_args --fake-upload"
fi
if ! [ -z "$justupdate" ]; then
	extra_args="$extra_args --just-update-info"
fi

while IFS= read -r entry; do

	echo "$entry"
	port=$(printf $entry | cut -d':' -f2)
	pno=$(printf "$entry" | awk '{print $2}')
	echo $port $pno
	if ! [ -z "$ports" ] && ! [[ "$ports" == *"$port"* ]]; then
		continue
	fi

	#files=""
	#for catalog in $(echo $catalogs | tr ',' ' '); do

	#	file=/nfs/exb/zinc22/2dpre_results/$catalog
		#if ! [ -f $file ]; then
		#	echo "$file cannot be found! generate this file and try again!"
		#	exit 1
		#fi
	#	files="${files}$file "

	#done
	#files=$(printf "$files" | head -c -1) # trim off the last whitespace
	if [ "$uploadtype" = "upload_zincid" ]; then
		transaction_id=$catalogs
	elif [ "$uploadtype" = "upload" ]; then
		transaction_id=$(echo $catalogs | tr ' ' '_')
	fi

	already_finished=$(psql -h $HOST -p $port -d tin -U tinuser --csv -c "select true from meta where varname = 'upload_name' and svalue = '$transaction_id'" | wc -l)

	if [ $already_finished -gt 1 ] && ! [ -z "$justupdate" ]; then
		transaction_id=${transaction_id}_update
		already_finished=$(psql -h $HOST -p $port -d tin -U tinuser --csv -c "select true from meta where varname = 'upload_name' and svalue = '$transaction_id'" | wc -l)
	elif [ $already_finished -le 1 ] && ! [ -z "$justupdate" ]; then
		echo "$HOST $port not uploaded to yet, won't update"
		continue
	fi

	if [ $already_finished -gt 1 ]; then
		echo $already_finished
		echo "$HOST $port" already uploaded
		continue
	fi

	if [ "$uploadtype" = "upload_zincid" ]; then
		echo $HOST $port tin $uploadtype $extra_args --source-dirs="$source_dirs" --transaction-id="$catalogs" --diff-destination="$diff_destination" >> $joblist_name
		echo $HOST $port tin $uploadtype $extra_args --source-dirs="$source_dirs" --transaction-id="$catalogs" --diff-destination="$diff_destination"
	elif [ "$uploadtype" = "upload" ]; then
		echo $HOST $port tin $uploadtype $extra_args --source-dirs="$source_dirs" --catalogs="$catalogs" --diff-destination="$diff_destination" >> $joblist_name
		echo $HOST $port tin $uploadtype $extra_args --source-dirs="$source_dirs" --catalogs="$catalogs" --diff-destination="$diff_destination"
	else
		echo "invalid upload type!"
		exit 1
	fi

done <<< "$(grep $HOST $BINDIR/common_files/database_partitions.txt)"



njobs=$(cat $joblist_name | wc -l)

# these jobs should receive a lion's share of a machine's resources while they're executing
# we want to avoid the OOM killer, therefore limit usage significantly
sbatch --mem=50G -c 20 -a 1-$njobs%$NPARALLEL -o $logdir/%a.out -w $HOST -J z22_snup_$uploadtype $BINDIR/runjob_2dload_new.bash $joblist_name $BINDIR
