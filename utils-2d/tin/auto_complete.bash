#!/bin/bash
# local script that will iterate through pending operations until they are complete or one fails

BINDIR=$(dirname $(realpath $0))

BASEDIR=$(dirname $(dirname $BINDIR))

source $BASEDIR/pyenv/bin/activate

HOST=$1
PORT=$2

most_recent=$(psql -h $HOST -p $PORT -d tin -U tinuser -c "select svalue from meta where varname = 'upload_name' having max(ivalue)")

starting_line=$(awk '{print $1 " " NR}' $BASEDIR/tin_upload_history.txt | grep $most_recent | awk '{print $2}')

while IFS= read -r line; do

	echo $line

	trans_id=$(echo $line | awk '{print $1}')
	optype=$(echo $line | awk '{print $2}')
	optional=$(echo $line | awk '{print $3}')
	sourcedir=$(echo $line | awk '{print $4}')
	diffdest=$(echo $line | awk '{print $5}')
	additional=$(echo $line | awk '{print $6}')

	if [ "$optional" = "yes" ]; then
		continue
	fi

	loadcmd="python $BASEDIR/2dload.py --port $PORT"

	if ! [ $optype = "diff3d" ]; then
		cmd="$loadcmd tin diff3d --source-dirs $sourcedir --diff-destination $diffdest --transaction-id $trans_id --tarball-ids $additional"
		echo $cmd
		$cmd
	elif [ $optype = "upload" ]; then
		cmd="$loadcmd tin upload --source-dirs $sourcedir --diff-destination $diffdest --catalogs $trans_id"
		echo $cmd
		$cmd
	else
		cmd="$loadcmd tin $optype --source-dirs $sourcedir --diff-destination $diffdest --transaction-id $trans_id"
		echo $cmd
		$cmd
	fi

	res=$?

	if ! [ -z $res ];
		echo "command failed!"
		echo "cmd=$cmd"
		echo "params=$line"
		break
	fi

done < <(tail -n+$starting_line $BASEDIR/tin_upload_history | grep -E -v '^#')
