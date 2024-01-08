#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
if ! [[ $BINDIR == /* ]]; then
	BINDIR=$PWD/$BINDIR
fi

user=s_btingle
pwfl=/nfs/exb/zinc22/tarballs/.pw
just_these_machines=$1

if ! [ -z "$just_these_machines" ]; then
	for machine_port in $(echo "$just_these_machines" | tr ',' '\n'); do
		machine=$(echo $machine_port | cut -d':' -f1)
		port=$(echo $machine_port | cut -d':' -f2)
		if [ $machine = $port ]; then
			port=""
		fi
echo		sshpass -f $pwfl ssh $user@$machine secret=$pwfl /bin/bash $BINDIR/update_all_confs.bash $BINDIR/target.conf $port
		$BINDIR/sshpass-install/bin/sshpass -f $pwfl ssh $user@$machine FORCE=$FORCE secret=$pwfl /bin/bash $BINDIR/update_all_confs.bash $BINDIR/target.conf $port
	done
	exit
fi

echo just_this_machine=$just_this_machine

for machine in $(cat $BINDIR/common_files/machines.txt); do
	if ! [ $machine = "$just_this_machine" ] && ! [ -z $just_this_machine ]; then
		continue
	fi
	echo $machine
echo    sshpass -f $pwfl ssh $user@$machine FORCE=$FORCE secret=$pwfl /bin/bash $BINDIR/update_all_confs.bash $BINDIR/target.conf
	$BINDIR/sshpass-install/bin/sshpass -f $pwfl ssh $user@$machine FORCE=$FORCE secret=$pwfl /bin/bash $BINDIR/update_all_confs.bash $BINDIR/target.conf
done
