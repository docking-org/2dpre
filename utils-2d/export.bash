#!/bin/bash

BINDIR=${BINDIR-$(dirname $0)}
BINDIR=${BINDIR-.}
source $BINDIR/../py36_psycopg2/bin/activate

output_base_dir=$1
p=$2

mkdir -p /local2/load/export_$p/tranches
chmod 777 /local2/load/export_$p
! [ -f /local2/load/export_$p/raw ] && psql -p $p -d tin -U tinuser --set=output_file=/local2/load/export_$p/raw -f $BINDIR/../psql/tin_export.pgsql
echo "$(date): finished export"

! [ -f /local2/load/export_$p/encoded ] && python $BINDIR/encode_zinc_ids.py /local2/load/export_$p/raw /local2/load/export_$p/encoded
echo "$(date): finished encoding"

cat /local2/load/export_$p/encoded | python $BINDIR/split_on_zinc_id.py /local2/load/export_$p/tranches 2
echo "$(date): finished split"

for tranche in /local2/load/export_$p/tranches/*; do

	tranchename=$(basename $tranche | cut -d'.' -f1)
	hac=$(echo $tranchename | awk '{print substr($1, 1, 3)}')
	mkdir -p $output_base_dir/$hac
	gzip $tranche
	mv $tranche.gz $output_base_dir/$hac/$tranchename.smi.gz

done

#rm -r /local2/load/export_$p
