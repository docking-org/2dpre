#!/bin/bash
partid=$1

source /dev/shm/build_3d/lig_build_py3-3.7.1/bin/activate
python $BINDIR/../2dload.py rollback $partid ,
bash $BINDIR/import_2d_substance.bash $partid
