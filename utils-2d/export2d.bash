#!/bin/bash

imageid=$1
EXPORT_LIST=$2
EXPORT_DEST=$3

if [ -z $imageid ] || [ -z $EXPORT_LIST ] || [ -z $EXPORT_DEST ]; then
	echo "supply all arguments please!"
	exit 1
fi

BINDIR=$(dirname $0)
BINDIR=${BINDIR-$PWD}

if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi

#EXPORT_LIST=su,mu
#EXPORT_DEST=/nfs/exb/zinc22/2d-anions

source /dev/shm/build_3d/lig_build_py3-3.7.1/bin/activate
bash diagnose_2d.bash $imageid | grep good | awk '{print $2}' > /dev/shm/partitions_to_export.bash

mkdir -p /local2/load/export/tmp
cd /local2/load/export/tmp

for pid in $(cat /dev/shm/partitions_to_export.bash); do
	pname=$(grep -w $pid $BINDIR/partitions.txt | awk '{print $1}')
	hac=$(printf $pname | awk '{print substr($1, 1, 3)}')
	if [ -z $FORCE ] && [ -f $EXPORT_DEST/$hac/$pname.smi.gz ]; then
		continue
	fi
	echo $pid

	python $BINDIR/../2dload.py export $pid $EXPORT_LIST

	for tranche in H*; do
		bname=$(printf $tranche | cut -d'.' -f1)
		hac=$(printf $tranche | awk '{print substr($1, 1, 3)}')
		mkdir -p $EXPORT_DEST/$hac
		gzip $tranche
		mv $tranche.gz $EXPORT_DEST/$hac/$bname.smi.gz
	done
done
