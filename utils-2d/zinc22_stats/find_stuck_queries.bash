#!/bin/bash
# utils-2d/zinc22_stats/find_stuck_queries.bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

days_threshold=${1-10}
particular_host=$2

for entry in $(cat $BINDIR/current_databases); do

	host=$(echo $entry | cut -d':' -f1)
	port=$(echo $entry | cut -d':' -f2)

	if ! [ -z $particular_host ]; then
		if ! [ $host = $particular_host ]; then
			continue
		fi
	fi

	res=$(psql -h $host -p $port -d tin -U tinuser --csv -c "SELECT pid, age(clock_timestamp(), query_start), usename, query FROM pg_stat_activity WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' AND age(clock_timestamp(), query_start) > interval '$days_threshold days' ORDER BY query_start desc" | grep -v ROLLBACK)

	if [ $(printf "$res" | wc -l) -eq 1 ]; then
		continue
	else
		echo $host:$port
		echo "$res" | tail -n+2
	fi
done


