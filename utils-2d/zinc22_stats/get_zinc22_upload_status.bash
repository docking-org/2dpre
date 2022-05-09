#!/bin/bash
# utils-2d/zinc22_stats/get_zinc22_patch_status.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

stats_file=$BINDIR/statistics/upload_status/upload_status_$(date "+%m_%d_%Y").txt

#current_patches="postgres escape substanceopt normalize_p1 normalize_p2"
#current_patches=$(cat $BINDIR/relevant_patches.txt)

#printf "%20s %20s %20s %20s %20s %20s\n" host:port ${current_patches} > $stats_file

printf "%20s %20s\n" host:port latest_upload > $stats_file
psqlargs="-d tin -U tinuser --csv"
for entry in $(cat $BINDIR/../common_files/current_databases.txt); do

	host=$(echo $entry | cut -d':' -f1)
        port=$(echo $entry | cut -d':' -f2)
	echo $host $port

	row=$(printf "%20s" $host:$port)
	tableexists=$(psql -h $host -p $port $psqlargs -c "select * from tin_meta limit 1")
	[ -z "$tableexists" ] && printf "%20s %20s\n" $host:$port na >> $stats_file
	#if [ -z "$tableexists" ]; then
	#	printf "$row %20s %20s %20s %20s %20s\n" na na na na na >> $stats_file
	#	continue
	#fi
	#for patch in $current_patches; do

		status=$(psql -h $host -p $port $psqlargs -c "select svalue from tin_meta where varname = 'upload_name' and ivalue in (select max(ivalue) from tin_meta where varname = 'upload_name' and svalue != '')" 2>/dev/null | tail -n 1)
		if [ "$status" = "svalue" ]; then
			status=na
		fi
		#if [ $(echo "$status" | wc -l) -lt 2 ]; then
		#	status=f
		#fi
		#status=$(echo "$status" | tail -n 1)
		#if [ "$status" = "f" ]; then
	#		status=false
		#elif [ "$status" = "t" ]; then
		#	status=true
		#fi
		#row=$(printf "$row %20s" $status)
	#done
	printf "%20s %20s\n" $host:$port $status >> $stats_file
done
