#!/bin/bash
# utils-2d/zinc22_stats/get_zinc22_patch_status.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

stats_file=$BINDIR/statistics/patch_status/patch_status_$(date "+%m_%d_%Y").txt

#current_patches="postgres escape substanceopt normalize_p1 normalize_p2"
current_patches=$(cat $BINDIR/relevant_patches.txt)

printf "%20s %20s %20s %20s %20s %20s\n" host:port ${current_patches} > $stats_file

psqlargs="-d tin -U tinuser --csv"
for entry in $(cat $BINDIR/current_databases); do

	host=$(echo $entry | cut -d':' -f1)
        port=$(echo $entry | cut -d':' -f2)
	echo $host $port

	row=$(printf "%20s" $host:$port)
	tableexists=$(psql -h $host -p $port $psqlargs -c "select * from patches limit 1")
	if [ -z "$tableexists" ]; then
		printf "$row %20s %20s %20s %20s %20s\n" na na na na na >> $stats_file
		continue
	fi
	for patch in $current_patches; do

		status=$(psql -h $host -p $port $psqlargs -c "select patched from patches where patchname='$patch'" 2>/dev/null)
		if [ $(echo "$status" | wc -l) -lt 2 ]; then
			status=f
		fi
		status=$(echo "$status" | tail -n 1)
		if [ "$status" = "f" ]; then
			status=false
		elif [ "$status" = "t" ]; then
			status=true
		fi
		row=$(printf "$row %20s" $status)
	done
	echo "$row" >> $stats_file
done
