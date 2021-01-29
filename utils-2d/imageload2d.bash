#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

imageid=$1

if [ -z $imageid ]; then
	echo "please supply an image id! exiting with error."
	exit 1
fi

export VERBOSE=
if [ -z $REFRESH_IMAGE ]; then
	bash $BINDIR/diagnose_2d.bash $imageid | grep -v "good" | awk '{print $2}' > /dev/shm/partitions_to_fix_$imageid.txt
else
	bash $BINDIR/diagnose_2d.bash $imageid | awk '{print $2}' > /dev/shm/partitions_to_fix_$imageid.txt
fi
#bash $BINDIR/diagnose_2d.bash $imageid | grep "good" | awk '{print $2}' > /dev/shm/partitions_to_postgres.txt

if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi
# export BINDIR for our slurm scripts to use- slurm scripts are copied to a a temp location, so they need a reference back to *this* BINDIR
export BINDIR

imageid=$1
if [ -z $imageid ]; then
	echo "supply an image id!"
	exit 1
fi

i=1
req_catalog=
for image in $(cat $BINDIR/images.txt); do
        if [ $i -eq $imageid ]; then
                req_catalog=$(printf "$image" | tr ',' '\n')
	fi
        i=$((i+1))
done

rm /dev/shm/prejobinfo_$imageid.txt
rm /dev/shm/prejoblist_$imageid.txt

log_base_dir=/nfs/exb/zinc22/2dload_logs
results_base_dir=/nfs/exb/zinc22/2dpre_results

slurmhost=$(hostname | cut -d'.' -f1)
nprejobs=0
for partid in $(cat /dev/shm/partitions_to_fix_$imageid.txt); do

	partname=$(cat $BINDIR/partitions.txt | grep -w $partid | awk '{print $1 "_" $2}')

	pre_jobids=""
	start=$nprejobs
	for catalog in $req_catalog; do
		if [ "$catalog" == "2d" ] && [ $imageid -eq 1 ]; then
			continue
		fi
		tranches=$(cat $BINDIR/tranches.txt | grep -w $catalog | awk '{print $1}')
		prefile=$results_base_dir/$catalog/$partid.pre
		if [ -f $prefile ]; then
			#echo $prefile
			ntranches=$(tar tf $prefile | wc -l)
			pstart=$(printf $partname | cut -d'_' -f1)
			pend=$(printf $partname | cut -d'_' -f2)
			nactual=$(python $BINDIR/get_partition_tranche_files.py NONE $pstart $pend | wc -l)
			#npresent=$(python get_partition_tranche_files.py $tranches $pstart $pend | grep -v MISSING | wc -l)
			if [ $ntranches -eq $nactual ]; then
				continue
			fi
			nprejobs=$((nprejobs+1))
			echo $partid $tranches $catalog >> /dev/shm/prejoblist_$imageid.txt
		else
			printf ""
			nprejobs=$((nprejobs+1))
			echo $partid $tranches $catalog >> /dev/shm/prejoblist_$imageid.txt
		fi
	done
	echo $((start+1)) $nprejobs $partname >> /dev/shm/prejobinfo_$imageid.txt

done

echo $req_catalog
echo REFRESH_IMAGE=$REFRESH_IMAGE
echo "about to start submitting in 5 seconds, ctrl-C to quit"
sleep 5

SRUN_ARGS="--parsable --priority=TOP -w $slurmhost"

runpre_max_parallel=8
mkdir -p $log_base_dir/runpre_${slurmhost}_${imageid}
prebatchid=$(sbatch $SRUN_ARGS -J runprex -o $log_base_dir/runpre_${slurmhost}_${imageid}/%a.out --array=1-$nprejobs%$runpre_max_parallel $BINDIR/2dprep_slurm.bash $imageid)
echo "submitted $nprejobs runpre jobs"

for partid in $(cat /dev/shm/partitions_to_fix_$imageid.txt); do

	logdir=$log_base_dir/$partid
	mkdir -p $logdir
	partname=$(cat $BINDIR/partitions.txt | grep -w $partid | awk '{print $1 "_" $2}')
	initid=$(sbatch $SRUN_ARGS -J 2dinitx -o $logdir/2dinit_${imageid}_$partid.out $BINDIR/2dinit_slurm.bash $partid $imageid)
	echo "init job id for $partid : $initid"

	pre_jobids=""
	prejobs=$(grep -w $partname /dev/shm/prejobinfo_$imageid.txt | awk '{print $1 "," $2}')
	prejobstart=$(printf $prejobs | cut -d',' -f1)
	prejobend=$(printf $prejobs   | cut -d',' -f2)
	echo $prejobstart $prejobend
	for i in $(seq $prejobstart $prejobend); do
		pre_jobids="$pre_jobids${prebatchid}_$i:"
	done
	
	echo "dependency: $pre_jobids$initid"	

	# create a dependency chain out of jobid
	# initialize the dependency chain with the preprocessing/init jobs
	jobid=$pre_jobids$initid
	for catalog in $req_catalog; do
		if [ $imageid -eq 1 ] && [ "$catalog" == "2d" ]; then
			continue
		fi
		log_out=$logdir/2dload_${partid}_${imageid}_$catalog.out
		prefile=$results_base_dir/$catalog/$partid.pre
		jobid=$(sbatch $SRUN_ARGS -J 2daddx -d afterok:$jobid -o $log_out $BINDIR/2dload_slurm.bash add $partid $prefile $catalog)
		echo "submitted load job: $jobid"
	done
done

exit 0
