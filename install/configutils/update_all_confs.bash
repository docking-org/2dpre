#!/bin/bash

target_conf=$1

for d in /local2/psql/12/data_sb*; do
	i=$(basename $d | tr -d '[:lower:]' | cut -d'_' -f2)
	echo $d ::: $i

	python3 update_psql_conf.py $target_conf $d/postgresql.conf > t.conf
	mv t.conf $d/postgresql.conf
	chown postgres:postgres $d/postgresql.conf

	systemctl restart postgresql${i}sb-12.service
done
