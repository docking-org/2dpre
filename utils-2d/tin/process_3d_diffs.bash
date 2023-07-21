#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

all_files_list=$1
dest=$2

while read -r line; do
	file=$(echo $line | awk '{print $1}')
	tranche=$(basename $file)
	hac=$(echo $tranche | awk '{print substr($1, 1, 3)}')
	mkdir -p $dest/$hac
	if [ -f $dest/$hac/${tranche}.smi ]; then
		echo "$file seems to be done: $dest/$hac/${tranche}.smi exists!"
		continue
	fi
	echo $file $tranche

	awk -v t=$tranche '{print $3 "\t" $1 "\t" t}' $file > /scratch/${tranche}.working.smi
	python $BINDIR/encode_zinc_ids.py /scratch/${tranche}.working.smi $dest/$hac/${tranche}.smi
	rm /scratch/${tranche}.working.smi
done < "$1"
