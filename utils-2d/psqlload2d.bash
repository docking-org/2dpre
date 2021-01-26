#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

imageid=$1

if [ -z $imageid ]; then
	echo "please supply an image id! exiting with error."
	exit 1
fi

PORT_START=${PORT_START-5434}
# all tin databases have a port numbering that starts at 5434 and increments from there
N_PORTS=$(netstat -plunt | grep ::54 | wc -l)
N_PORTS=${N_PORTS-15}

bash $BINDIR/diagnose_2d.bash $imageid | grep "good" | awk '{print $1}' > /dev/shm/partitions_to_postgres.txt

if ! [[ $BINDIR == /* ]]; then
        BINDIR=$PWD/$BINDIR
fi
export BINDIR

# there are a limited number of ports, so we load by priority so that they aren't wasted, in case there aren't enough for everyone
function get_priority {
	part=$(basename $1)
	part=$(printf "$part" | tr '_' ' ')
	grep "$part" $BINDIR/partition_priority.txt | awk '{print $3 " " $4}'
}

for partition in $(cat /dev/shm/partitions_to_postgres.txt); do

	if ! [ -f $partition/.port ]; then
		prio=$(get_priority $(basename $partition))
		echo $partition $prio
	else
		PORT_START=$((PORT_START+1))
		N_PORTS=$((N_PORTS-1))
	fi
done > /dev/shm/psql_partitions_priority.txt

sort -k3,3n /dev/shm/psql_partitions_priority.txt | awk '{print $1 "_" $2}' | head -n $N_PORTS > /dev/shm/psql_partitions_to_load.txt

#echo $PORT_START
#echo $N_PORTS

if [ $N_PORTS -le 0 ]; then
	echo No more postgres ports available! Allocate some more or relocate some databases.
	echo The following databases need ports:
	for partition in $(cat /dev/shm/partitions_to_postgres.txt); do
		if ! [ -f $partition/.port ]; then
			echo $partition
		fi
	done
else
	echo $N_PORTS postgres ports available! Loading now...
fi

slurmhost=$(hostname | cut -d'.' -f1)
logdir=/nfs/exb/zinc22/2dload_logs
nparts=$(cat /dev/shm/psql_partitions_to_load.txt | wc -l)
for port in $(seq $PORT_START $((PORT_START+N_PORTS))); do

        mkdir -p $logdir/psql_$slurmhost
	idx=$((port-PORT_START+1))
	part=$(head -n $idx /dev/shm/psql_partitions_to_load.txt | tail -n 1)
	if [ $idx -gt $nparts ]; then
		break
	fi
	echo $port $part
	partname=$(printf "$part" | cut -d'_' -f1-2)
	partid=$(printf "$part" | cut -d'_' -f3)
	echo "binding $partid to $port and wiping existing data"
	python $BINDIR/../2dload.py postgres $partid bind $port
	python $BINDIR/../2dload.py postgres $partid clear
	#if [ $imageid -ne 1 ]; then
	#	sbatch --priority=TOP -w $slurmhost -o $logdir/psql_$slurmhost/%j_$port.out -J 2dpsql $BINDIR/2dload_slurm.bash postgres $partid upload_smart $port
        #else
	#	sbatch --priority=TOP -w $slurmhost -o $logdir/psql_$slurmhost/%j_$port.out -J 2dpsql $BINDIR/2dload_slurm.bash postgres $partid upload_full $port
	#fi
done

for partition in $(cat /dev/shm/partitions_to_postgres.txt); do
	partname=$(basename $partition | tr '_' ' ')
	partid=$(grep -w "$partname" $BINDIR/partitions.txt | awk '{print $3}')
	jobid=$(sbatch --parsable --priority=TOP -w $slurmhost -o $logdir/psql_$slurmhost/2dpsql_$partid_$port.out -J 2dpsqlx $BINDIR/2dload_slurm.bash postgres $partid upload_smart)
	echo "launched upload_smart job for $partid with jobid=$jobid"
done
