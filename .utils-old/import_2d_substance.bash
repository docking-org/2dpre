#!/bin/bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

partition_id=$1
partition=$(grep -w $partition_id $BINDIR/partitions.txt | awk '{print $1 "_" $2}')

LOAD_BASE=/local2/load
ORIG=$(printf "/nfs/exb/zinc22/2d\n")

max_id=0
len_substance=0
for tranche in $LOAD_BASE/$partition/src/H??????; do

	echo $tranche
	rm -r $tranche/*
	hcount=$(echo $(basename $tranche) | awk '{print substr($1, 1, 3)}')

	for orig in $ORIG; do
		echo $orig/$hcount/$(basename $tranche)
		file=$orig/$hcount/$(basename $tranche).smi.gz
		if ! [ -f $file ]; then
			echo "orig file not present! Not an issue."
			touch $tranche/orig
			gzip $tranche/orig
		else
			cp $file $tranche/orig.gz
		fi
		gzip -d $tranche/orig.gz
		date=$(date +%m.%d.%H.%M)
		archive=$tranche/${date}_$(basename $orig)
		mkdir $archive
		python $BINDIR/decode_zinc_ids.py $tranche/orig | awk '{print $1 " MISSING " $2}' > $archive/sub
		maxid=$(cat /tmp/$(basename $tranche).maxid)
		if [ $maxid -gt $max_id ]; then
			max_id=$maxid
		fi
		touch $archive/sup
		touch $archive/cat
		subl=$(cat $archive/sub | wc -l)
		cat $archive/sub >> $tranche/substance.txt
		gzip $archive/*
		echo 0 > $archive/.supl
		echo 0 > $archive/.catl
		echo $subl > $archive/.subl
		tar -C $tranche -czf $tranche/$(basename $archive).tar.gz $(basename $archive)
		rm -r $archive
		rm $tranche/orig
		len_substance=$((subl+len_substance))
	done

	touch $tranche/supplier.txt
	touch $tranche/catalog.txt

done

# sometimes the max id number is more than the actual length
# this causes problems
# use a disgusting hack to get around the problem
if [ $max_id -gt $len_substance ]; then

	diff=$((max_id-len_substance))
	dummysrc=$LOAD_BASE/$partition/src/HXXYXXX
	mkdir $dummysrc
	dummyarchive=$dummysrc/11.11.11.11_2d
	mkdir $dummyarchive
	touch $dummyarchive/sup
	touch $dummyarchive/cat
	seq 1 $diff > $dummyarchive/sub
	cp $dummyarchive/sub $dummysrc/substance.txt
	gzip $dummyarchive/*
	echo $diff > $dummyarchive/.subl
	echo 0 > $dummyarchive/.supl
	echo 0 > $dummyarchive/.catl
	tar -C $dummysrc -czf $dummyarchive.tar.gz $(basename $dummyarchive)
	rm -r $dummyarchive
	
	len_substance=$max_id
	
elif [ $max_id -lt $len_substance ]; then
	echo "something is wrong! max id encountered < length of input"
	echo "lets fix this..."
fi

echo 0 > $LOAD_BASE/$partition/src/.len_supplier
echo 0 > $LOAD_BASE/$partition/src/.len_catalog
echo $len_substance > $LOAD_BASE/$partition/src/.len_substance
