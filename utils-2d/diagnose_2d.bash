#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

IMAGEID=$1

find /local2/load -maxdepth 1 -name 'H??????_H??????' > /tmp/present_partitions.txt
if [ -f /tmp/partitions_to_fix.txt ]; then
        rm /tmp/partitions_to_fix.txt
fi

#S_TRANCHES=/mnt/nfs/exa/work/jyoung/phase2_tranche/phase2_s/real2021-s_tranches
#M_TRANCHES=/mnt/nfs/exa/work/jyoung/phase2_tranche/phase2_m
#SU_TRANCHES=/mnt/nfs/db5/zinc22/2d/vendors/enamine/2020-10/2020q1-3_REAL_Space_Acids_345M_tranches/S_345M_smiles
#MU_TRANCHES=/mnt/nfs/db5/zinc22/2d/vendors/enamine/2020-10/2020q1-3_REAL_Space_Acids_345M_tranches/M_345M_smiles

req_catalog=
i=1
for image in $(cat $BINDIR/images.txt); do
	if [ $i -gt $IMAGEID ]; then
		break
	fi
	if [ $i -eq 1 ]; then
		req_catalog=$image
	else
		req_catalog=${req_catalog},$image
	fi
	i=$((i+1))
done

#echo $req_catalog


for partition in $(cat /tmp/present_partitions.txt); do

        start=$(echo $(basename $partition) | cut -d'_' -f1)
        partid=$(grep "$start" $BINDIR/partitions.txt | awk '{print $3}')
	for tranche in $(ls $partition/src | grep "^H[0-9].*"); do
		#! [ -z $VERBOSE ] && echo $tranche
		tranche=$partition/src/$tranche
        	present_catalogues=$(find $tranche -name '*.tar.gz' | wc -l)
		missing=
		shorts=$(find $tranche -name '*.tar.gz' | xargs -n 1 basename 2>&0 | cut -d'_' -f2 | cut -d'.' -f1)
		for short in $(printf $req_catalog | tr ',' '\n'); do
			contains=$(printf "$shorts" | grep -w $short | wc -l)
			if [ $contains -eq 0 ]; then
				test -z $missing && missing=$short || missing=$missing,$short
			fi
		done
        	if ! [ -z "$missing" ]; then
			if [ -z $broken ]; then
				echo "$partition $partid bad"
				broken=TRUE
			fi
			if [ -z $VERBOSE ]; then
				break
			fi
			echo $tranche $missing
        	fi
	done
	if [ -z $broken ]; then
		echo "$partition $partid good"
	fi
	broken=
done
