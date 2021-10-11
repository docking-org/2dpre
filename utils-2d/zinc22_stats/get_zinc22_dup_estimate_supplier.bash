#!/bin/bash
# utils-2d/zinc22_stats/get_zinc22_dup_estimate_supplier.bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

stats_file=$BINDIR/statistics/dup_estimates/dup_est_supplier_$(date "+%m_%d_%Y").txt
printf "host:port\testimated duplicates per 100000 rows\n" > $stats_file

for entry in $(cat $BINDIR/current_databases); do

        host=$(echo $entry | cut -d':' -f1)
        port=$(echo $entry | cut -d':' -f2)
        echo $host $port

	psql -h $host -p $port -d tin -U tinuser --csv -f $BINDIR/get_dup_estimate_supplier.pgsql > /tmp/dupestsup_tmp.txt 2>/dev/null
	
	dupval=$(tail -n 2 /tmp/dupestsup_tmp.txt | head -n 1)
	if [ "$dupval" = "BEGIN" ]; then
		dupval="NA"
	fi

	echo $host:$port $dupval >> $stats_file

done
