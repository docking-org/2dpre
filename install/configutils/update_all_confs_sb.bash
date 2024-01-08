#!/bin/bash

target_conf=$1

free_mem_mb=$(free --mega | awk '{print $2}' | tail -n 2 | head -n 1)
free_mem_mb_25=$(python -c "print(int($free_mem_mb * 0.25))")
export free_mem_mb_25

for d in /local2/psql/12/data_sb*; do
	i=$(basename $d | tr -d '[:lower:]' | cut -d'_' -f2)
	echo $d ::: $i

	python3 update_psql_conf.py $target_conf $d/postgresql.conf > /tmp/t.conf
	mv /tmp/t.conf $d/postgresql.conf
	chown postgres:postgres $d/postgresql.conf

	systemctl restart postgresql${i}sb-12.service
done
