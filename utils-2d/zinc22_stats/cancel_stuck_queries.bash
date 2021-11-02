#!/bin/bash
#! utils-2d/zinc22_stats/cancel_stuck_queries.bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

days_threshold=${1-10}
particular_host=$2

for entry in $(cat $BINDIR/../common_files/current_databases.txt); do

	host=$(echo $entry | cut -d':' -f1)
	port=$(echo $entry | cut -d':' -f2)

	if ! [ -z $particular_host ]; then
		if ! [ $host = $particular_host ]; then
			continue
		fi
	fi

	res=$(psql -h $host -p $port -d tin -U tinuser --csv -c "select pg_cancel_backend(t.pid), pid from (SELECT pid FROM pg_stat_activity WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND age(clock_timestamp(), query_start) > interval '$days_threshold days' ORDER BY query_start desc) t")

	#if [ $(printf "$res" | wc -l) -eq 1 ]; then
#		continue
#	else
		echo $host:$port
		echo "$res" | tail -n+2
#	fi
done


