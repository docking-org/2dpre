#!/bin/bash
# utils-2d/zinc22_stats/get_zinc22_table_size_ests.bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

stats_file=$BINDIR/statistics/table_sizes/table_sizes_$(date "+%m_%d_%Y").txt

printf "sub_est\tsup_est\tcat_est\n" > $stats_file

for entry in $(cat $BINDIR/../common_files/current_databases.txt); do

	host=$(echo $entry | cut -d':' -f1)
	port=$(echo $entry | cut -d':' -f2)
	echo $host:$port

	est_sub=$(psql -h $host -p $port -d tin -U tinuser --csv -c "SELECT reltuples AS estimate FROM pg_class where relname = 'substance'" | tail -n 1)
	est_sup=$(psql -h $host -p $port -d tin -U tinuser --csv -c "SELECT reltuples AS estimate FROM pg_class where relname = 'catalog_content'" | tail -n 1)
	est_cat=$(psql -h $host -p $port -d tin -U tinuser --csv -c "SELECT reltuples AS estimate FROM pg_class where relname = 'catalog_substance'" | tail -n 1)

	printf "$entry\t%E\t%E\t%E\n" $est_sub $est_sup $est_cat >> $stats_file

done
