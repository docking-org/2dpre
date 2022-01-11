BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

partition_id=$1
output_dest=$2

[ -z $partition_id ] && echo "please supply partition id" && exit 1
[ -z $output_dest ] && echo "please supply output dest" && exit 1

database=$(grep -w $partition_id $BINDIR/common_files/database_partitions.txt)
host=$(echo $database | awk '{print $1}' | cut -d':' -f1)
port=$(echo $database | awk '{print $1}' | cut -d':' -f2)

partition=$(grep -w $partition_id $BINDIR/common_files/partitions.txt)
pstart=$(echo $partition | awk '{print $1}')
pfinal=$(echo $partition | awk '{print $2}')

echo $host $port $pstart $pfinal

ZINCID_POS=${ZINCID_POS-2}
TARGET_DIRECTORY=${TARGET_DIRECTORY-/nfs/exb/zinc22/2d-01}

for tranche in $(python $BINDIR/get_partition_tranche_files.py NONE $pstart $pfinal); do

	echo $(date +%X): $tranche
	hac=$(echo $tranche | awk '{print substr($1, 1, 3)}')
	tranche_id=$(psql -h $host -p $port -d tin -U tinuser --csv -c "select tranche_id from tranches where tranche_name = '$tranche'" | tail -n 1)
	zcat $TARGET_DIRECTORY/$hac/${tranche}.smi.gz | python3 $BINDIR/zincids_to_sub.py - - $tranche_id $ZINCID_POS >> $output_dest

done	
