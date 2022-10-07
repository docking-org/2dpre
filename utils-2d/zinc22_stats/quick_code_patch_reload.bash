#!/bin/bash
# alternative pathway to apply code-only patches to system
# since code-only patches don't actually change the database, it should be safe to apply them whenever
# doesn't require previous patches to be applied
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

patch_name=$1
patch_code=$2

for d in $(cat $BINDIR/common_files/current_databases.txt); do

	host=$(echo $d | cut -d':' -f1)
	port=$(echo $d | cut -d':' -f2)
	echo $host:$port
	psql -h $host -p $port -d tin -U tinuser -f $patch_code
	res=$?
	if [ -z $res ]; then
		res=$(psql -h $host -p $port -d tin -U tinuser --csv -c "select patched from patches where patchname='$patch'" | tail -n 1)
		if [ -z "$res" ]; then
			psql -h $host -p $port -d tin -U tinuser -c "insert into patches(patchname, patched) (values ('$patch', true))"
		else
			psql -h $host -p $port -d tin -U tinuser -c "update patches set patched=true where patchname='$patch'"
		fi
	fi
done
