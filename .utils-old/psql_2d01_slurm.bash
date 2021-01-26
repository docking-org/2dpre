#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

PORT_START=${PORT_START-5434}
N_PORTS=${N_PORTS-15}

bash $BINDIR/diagnose_2d01.bash | grep "good" | awk '{print $1}' > /dev/shm/partitions_to_postgres.txt

if ! [[ $BINDIR == /* ]]; then
        BINDIR=$PWD/$BINDIR
fi
export BINDIR

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

echo $PORT_START
echo $N_PORTS

slurmhost=$(hostname | cut -d'.' -f1)
logdir=/nfs/exb/zinc22/2dload_logs
nparts=$(cat /dev/shm/psql_partitions_to_load.txt | wc -l)
for port in $(seq $PORT_START $((PORT_START+N_PORTS))); do

        mkdir -p $logdir/psql_$slurmhost
	idx=$((port-PORT_START+1))
	part=$(head -n $idx /dev/shm/psql_partitions_to_load.txt | tail -n 1)
	if [ $idx -gt $nparts ]; then
		exit
	fi
	echo $port $part
	partname=$(printf "$part" | cut -d'_' -f1-2)
	partid=$(printf "$part" | cut -d'_' -f3)
	python $BINDIR/../2dload.py postgres $partid bind $port
	sbatch --priority=TOP -w $slurmhost -o $logdir/psql_$slurmhost/%j_$port.out -J 2dpsql $BINDIR/load_2d_wrapper_slurm.bash postgres $partid upload_full $port

done
