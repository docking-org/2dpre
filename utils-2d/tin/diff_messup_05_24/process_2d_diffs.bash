#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
BINDIR=$(realpath $BINDIR)

diff_loc=$1
source_loc=$2
#all_files_list=$1
dest=$3

WORKDIR=/scratch/$(whoami)/process_diff_working
mkdir -p $WORKDIR
pushd $WORKDIR

for d in $diff_loc/*/sub; do
	db=$(basename $(dirname $d))
	host=$(echo $db | cut -d':' -f1)
	port=$(echo $db | cut -d':' -f2)
	echo "converting sub ids for $d"
	mkdir $WORKDIR/tranches
	cd $WORKDIR/tranches
	cat $d/*.new | awk '{print $1 "\t" $2 "\t" $3 > $3}'
	for t in H??????; do
		echo "resolving $t"
		hac=$(echo $t | awk '{print substr($1, 1, 3)}')
		#if [ -f $dest/$hac/$t.smi ]; then
		#	echo "already complete!"
		#	continue
		#fi
		awk -v t=$t '{print $1 "\t" 0 "\t" t}' $source_loc/$hac/$t.smi | sort -k1 -k2nr - $t > $t.sorted
		rev $t.sorted | uniq -f2 -u | rev | awk '{print $1}' > $t.old
	done
	echo "resolving all on database..."
	cat *.old | psql -E -t --csv -h $host -p $port -d tin -U tinuser -f $BINDIR/resolve_smiles_ids.pgsql | tail -n+3 > resolved
	echo "splitting back to tranches..."
	awk '{print $1 "\t" $2 "\t" $3 > $3".smi"}' resolved
	for t in H*.smi; do
		newt=$(echo $t | cut -d'.' -f1) # get the new ids as well
		echo "encoding & finalizing $t"
		#if [ -f $dest/$hac/$t.smi ]; then
		#	echo "already complete!"
		#	continue
		#fi
		cat $t $newt | python $BINDIR/encode_zinc_ids.py - $t.enc
		mkdir -p $dest/$hac
		cp $t.enc $dest/$hac/$t
	done
	echo "all done with $d"
	cd ..
	rm -r $WORKDIR/tranches
	#echo "cat" *.old "|" psql -h $host -p $port -d tin -U tinuser -f $BINDIR/resolve_smiles_ids.pgsql ">" $t.resolved
	#cat *.old > /scratch/allold
	#cat *.old | psql -h $host -p $port -d tin -U tinuser -f $BINDIR/resolve_smiles_ids.pgsql > resolved
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
