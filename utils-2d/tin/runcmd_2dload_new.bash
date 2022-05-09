#!/bin/bash
# utils-2d/runcmd_2dload_new.bash
# req: BINDIR
PORT=$1
ARGS=$2

echo "start: `date`"
python3 $BINDIR/../2dload_new.py $PORT $ARGS
echo "end: `date`"
