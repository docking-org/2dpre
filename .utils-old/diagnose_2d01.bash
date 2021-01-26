#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

find /local2/load -maxdepth 1 -name 'H??????_H??????' > /tmp/present_partitions.txt
if [ -f /tmp/partitions_to_fix.txt ]; then
        rm /tmp/partitions_to_fix.txt
fi

S_TRANCHES=/mnt/nfs/exa/work/jyoung/phase2_tranche/phase2_s/real2021-s_tranches
M_TRANCHES=/mnt/nfs/exa/work/jyoung/phase2_tranche/phase2_m
SU_TRANCHES=/mnt/nfs/db5/zinc22/2d/vendors/enamine/2020-10/2020q1-3_REAL_Space_Acids_345M_tranches/S_345M_smiles
MU_TRANCHES=/mnt/nfs/db5/zinc22/2d/vendors/enamine/2020-10/2020q1-3_REAL_Space_Acids_345M_tranches/M_345M_smiles

for partition in $(cat /tmp/present_partitions.txt); do

        start=$(echo $(basename $partition) | cut -d'_' -f1)
        partid=$(grep "$start" $BINDIR/partitions.txt | awk '{print $3}')
	for tranche in $(ls $partition/src | grep "^H[0-9].*"); do
		tranche=$partition/src/$tranche
        	present_catalogues=$(find $tranche -name '*.tar.gz' | wc -l)
        	if ! [ $present_catalogues -eq 5 ]; then
                	if [ -z $found ]; then
				echo "$partition $partid bad"
				broken=TRUE
			fi
			if [ -z $VERBOSE ]; then
				break
			fi
			found=TRUE
			echo $tranche
        	fi
	done
	if [ -z $broken ]; then
		echo "$partition $partid good"
	fi
	broken=
	found=
done
