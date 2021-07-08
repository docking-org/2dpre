#!/bin/bash
# req: BINDIR
PORT=$1
ARGS=$2

echo "start: `date`"
python3 $BINDIR/../2dload_new.py $PORT $ARGS
echo "end: `date`"
