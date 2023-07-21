#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi

if [ -z $USE_HIST ]; then

	current_hist=$BINDIR/statistics/current_hist/current_hist_$(date "+%m_%d_%Y").csv
	mkdir -p $(dirname $current_hist)
	if ! [ -f $current_hist ]; then
		psql -h n-1-17 -p 5434 -U tinuser -d tin -c "copy (select * from meta where varname in ('version', 'upload_name')) to stdout with (format csv)" > $current_hist
	fi

else
	current_hist=$USE_HIST
fi

machines=$@

for machine in $machines; do
	echo $machine
	host=$(echo $machine | cut -d':' -f1)
	port=$(echo $machine | cut -d':' -f2)
	psql -h $host -p $port -d tin -U tinuser --set=hist=$current_hist -f $BINDIR/fake_history_zinc22.pgsql
done
