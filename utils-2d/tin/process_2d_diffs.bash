#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
BINDIR=$(realpath $BINDIR)

diff_loc=$1
#all_files_list=$1
dest=$2

WORKDIR=/scratch/$(whoami)/process_diff_working
mkdir -p $WORKDIR
pushd $WORKDIR

for d in $diff_loc/*/sub; do
	echo "converting sub ids for $d"
	cat $d/*.old $d/*.new | awk '{print $1 "\t" $2 "\t" $3}' | python $BINDIR/encode_zinc_ids.py - $WORKDIR/zid
	mkdir $WORKDIR/tranches
	cd $WORKDIR/tranches
	echo "creating tranches"
	awk '{print $1 "\t" $2 > $3}' $WORKDIR/zid
	echo "copying out"
	for t in H*; do
		hac=$(echo $t | awk '{print substr($1, 1, 3)}')
		mkdir -p $dest/$hac
		cp $t $dest/$hac/$t.smi
		echo "$t > $dest/$hac/$t.smi"
	done
done

#while read -r line; do
#	file=$(echo $line | awk '{print $1}')
	#tranche=$(basename $file)
	#hac=$(echo $tranche | awk '{print substr($1, 1, 3)}')
	#mkdir -p $dest/$hac
	#if [ -f $dest/$hac/${tranche}.smi ]; then
	#	echo "$file seems to be done: $dest/$hac/${tranche}.smi exists!"
	#	continue
	#fi
	#echo $file $tranche


	#awk -v t=$tranche '{print $3 "\t" $1 "\t" t}' $file > /scratch/${tranche}.working.smi
#	python $BINDIR/encode_zinc_ids.py /scratch/${tranche}.working.smi $dest/$hac/${tranche}.smi
#	rm /scratch/${tranche}.working.smi
#done < "$1"
