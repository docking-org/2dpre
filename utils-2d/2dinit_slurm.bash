#!/bin/bash
# req: BINDIR
partid=$1
imageid=$2

if [ -z $imageid ]; then
	echo "please do not forget to supply an image argument"
	echo "exiting with error"
	exit 1
fi

i=1
req_catalog=
for image in $(cat $BINDIR/images.txt); do
	if [ $i -ge $imageid ]; then
		break
	fi
	[ -z "$req_catalog" ] && req_catalog=$image || req_catalog=$req_catalog,$image
	i=$((i+1))
done
req_catalog=${req_catalog-,}
echo $req_catalog
sleep 1

source /dev/shm/build_3d_common/lig_build_py3-3.7.1/bin/activate
python $BINDIR/../2dload.py rollback $partid $req_catalog
if [ $imageid -eq 1 ]; then
	bash $BINDIR/import_2d_substance.bash $partid
fi
