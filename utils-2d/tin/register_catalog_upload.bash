#!/bin/bash

BINDIR=$(realpath $0)
BINDIR=$(dirname $BINDIR)

echo "list of super catalogs:"
pg="psql -h n-1-17 -p 5534 -d zinc22_common -U zincuser"
$pg -c "select * from catalog_super"

upload_hist=$BINDIR/common_files/tin_upload_history.txt

read -p "create new super catalog? [y/N]: " yn

if [ $yn = "y" ]; then

	read -p "name of new super catalog: " catname

	next_id=$($pg --csv -c "select max(super_id)+1 from catalog_super" | tail -n 1)

	$pg -c "insert into catalog_super(super_name, super_id) (values ('$catname', $next_id))"
	exit $?

fi

bash $BINDIR/history_sync.bash down $upload_hist
read -p "create new upload? [y/N]: " yn

if [ $yn = "y" ]; then

	read -p "name of new upload: " catname
	read -p "super catalog id of new upload: " superid
	read -p "source location of new upload: " src
	read -p "diff destination of new upload: " diffdest
	read -p "is new upload optional? [y/N]: " opt

	if [ $opt = "y" ]; then
		opt="yes"
		catname="$catname*"
	else
		opt="no"
	fi

	t=$(mktemp)
	already_exists=$(tail -n+2 $upload_hist | grep -E -v '^#' | awk '{print $1}' | grep -w $catname | wc -l)
	if [ $already_exists = 0 ]; then

		echo "blahblash" > $t
		echo -e "$catname\tupload\t$opt\t$src\t$diffdest\tsuper=$superid" >> $t

	fi

	bash $BINDIR/history_sync.bash up $t
	bash $BINDIR/history_sync.bash down $upload_hist

	rm $t

fi
