#!/bin/bash

BINPATH=${BINPATH-/nfs/home/xyz/btingle/bin/2dload/utils-2d}

source /dev/shm/build_3d_common/lig_build_py3-3.7.1/bin/activate

export TMPDIR=/local2/load
python $BINPATH/../2dload.py ${@:1}
