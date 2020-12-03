#!/bin/bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

has_missing_field=$($BINDIR/has_missing_field.bash)

for src in $has_missing_field; do

	echo $src

	for ball in $src/*.tar.gz; do

		echo $ball
		untarred=$(printf $ball | cut -d'.' -f1-4)
		
		tar -C $src -xzf $ball
		gzip -d $untarred/sup.gz
		nf=$(head -n 1 $untarred/sup | awk '{print NF}')		

		if [ $nf -eq 2 ]; then
			echo "fixing $ball"
			awk '{print $0 " " 0}' $untarred/sup > $untarred/sup.tmp
			mv $untarred/sup.tmp $untarred/sup
			gzip $untarred/sup
			pushd $src > /dev/null 2>&1
			tar -czf $(basename $ball) $(basename $untarred)
			popd > /dev/null 2>&1
		fi

		rm -r $untarred

	done

	awk '{if (NF == 2) { print $0 " " 0 } else { print $0 }}' $src/supplier.txt > $src/supplier.tmp
	mv $src/supplier.tmp $src/supplier.txt

done
