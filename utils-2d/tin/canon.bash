#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

input_file=$1
canon_out=${2}.canon.smi
noncanon_out=${2}.noncanon.smi

# this particular script uses the same environment as the preprocessing scripts
python=/nfs/soft/www/apps/tin01/envs/development/bin/python

if ! [[ "$input_file" == *'.gz' ]]; then
	cat $input_file | $python $BINDIR/canon.py $canon_out $noncanon_out
	! [ -z $GZ_OUTPUT ] && gzip $canon_out $noncanon_out
else
	zcat $input_file | $python $BINDIR/canon.py $canon_out $noncanon_out
	! [ -z $GZ_OUTPUT ] && gzip $canon_out $noncanon_out
fi
