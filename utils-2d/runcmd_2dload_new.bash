#!/bin/bash
PORT=$1
ARGS=$2

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

python3 $BINDIR/../2dload_new.py $PORT $ARGS