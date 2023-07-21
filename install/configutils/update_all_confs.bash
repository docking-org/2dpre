#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi

target_conf=$1
target_port=$2

dbs_all=$(cat $secret | sudo -p '' -S find /local2/psql/12 -maxdepth 1 -type d -name 'data*')
for db in $dbs_all; do
	if [[ $(basename $db) == *old ]] || [ $(basename $db) = "data" ]; then
	#if [[ $(basename $db) == *sb* ]] || [[ $(basename $db) == *old ]] || [ $(basename $db) = "data" ]; then
                continue
	fi
	echo $db
	[ -z "$dbs" ] && dbs=$db || dbs="$dbs $db"
done

ndbs=$(echo "$dbs" | tr ' ' '\n' | wc -l)

echo $dbs
echo $ndbs

free_mem_mb=$(free --mega | awk '{print $2}' | tail -n 2 | head -n 1)
free_mem_mb_25=$(python -c "print(int($free_mem_mb * (0.75/$ndbs)))") 
# 0.75 ensures no more than 75% of system ram will be used across all instances summed together
# unfortunately, the way the databases are configured means they can't actually share shared memory, meaning if instance A allocated 50G, it won't be available for instance B to allocate
# we need to change it so that there is one postgres instance per machine with multiple databases instead of multiple instances per machine
echo $free_mem_mb_25 / $free_mem_mb used per db
export free_mem_mb_25

for d in $dbs; do
	#if [[ $(basename $d) == *sb* ]] || [[ $(basename $d) == *old ]]; then
	#	continue
	#fi
	if [[ $(basename $d) == *old ]]; then
		continue
	fi
	# dont reconfigure antimony databases here, but include them for calculating amt of shared memory
	if [[ $(basename $d) == *sb* ]]; then
		antimony=t
	else
		antimony=
	fi
	i=$(basename $d | tr -d '[:lower:]' | cut -d'_' -f2)
	port=$((5433+i))
	# test database lock to see if anyone is around
	flock -w 0 /tmp/zinc22_pg_${port}.lock printf ''
	e=$?
	if ! [ $e = "0" ]; then
		echo $d ::: $i ::: $port ::: currently running, wont restart
		continue
	fi
	if ! [ -z $target_port ]; then
		if [ $port -ne $target_port ]; then
			continue
		fi
		port=$target_port
	fi
	echo $d ::: $i ::: $port

	if [ -z $antimony ]; then
		np=$(psql --csv -t -p $port -d tin -U tinuser -c "select ivalue from meta where svalue = 'n_partitions'" | tail -n 1)
		if [ -z $np ]; then
			continue
		fi
	else
		np=128
	fi

	cat $secret | sudo -p '' -S npartitions=$np free_mem_mb_25=$free_mem_mb_25 python3 $BINDIR/update_psql_conf.py $target_conf $d/postgresql.conf > /tmp/t.conf
	cat $secret | sudo -p '' -S cp $d/postgresql.conf /tmp/true.conf
	n_diff=$(diff /tmp/true.conf /tmp/t.conf | wc -l)
	if [ $n_diff -gt 0 ]; then
		echo "conf is different, will install"
	elif [ -z $FORCE ]; then
		echo "conf is same, will skip"
		continue
	fi
	cat $secret | sudo -p '' -S mv /tmp/t.conf $d/postgresql.conf

	cat $secret | sudo -p '' -S chown postgres:postgres $d/postgresql.conf
	cat $secret | sudo -p '' -S systemctl restart postgresql${i}-12.service &

	if ! [ -z $target_port ]; then
		exit
	fi
done

wait
