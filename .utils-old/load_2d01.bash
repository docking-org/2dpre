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
	firsttranche=$(ls $partition/src | head -n 1)
	present_catalogues=$(find $partition/src/$firsttranche -name '*.tar.gz' | wc -l)
	if [ $present_catalogues -eq 5 ]; then
		echo "$partition seems to be loaded, moving on..."
	else
		echo "$partition needs to be fixed..."
		echo ${partition}_${partid} >> /tmp/partitions_to_fix.txt
	fi

done
echo "done diagnosing, ctrl-C to stop, else in 5 seconds loading will start"

sleep 5

for partition in $(cat /tmp/partitions_to_fix.txt); do
	partname=$(echo $partition | cut -d'_' -f1-2)
	partid=$(echo $partition | cut -d'_' -f3)
	echo $partname

	python $BINDIR/../2dload.py rollback $partid ,
	bash $BINDIR/import_2d_substance.bash $partid

	echo "starting preprocessing work on $partname, $partid"
	if ! [ -f /nfs/exb/zinc22/2dpre_results/s/$partid.pre ]; then
	bash $BINDIR/../preprocessing/pre_process_partition.bash $partid $S_TRANCHES s &
	fi
	if ! [ -f /nfs/exb/zinc22/2dpre_results/m/$partid.pre ]; then
	bash $BINDIR/../preprocessing/pre_process_partition.bash $partid $M_TRANCHES m &
	fi
	if ! [ -f /nfs/exb/zinc22/2dpre_results/su/$partid.pre ]; then
	bash $BINDIR/../preprocessing/pre_process_partition.bash $partid $SU_TRANCHES su &
	fi
	if ! [ -f /nfs/exb/zinc22/2dpre_results/mu/$partid.pre ]; then
	bash $BINDIR/../preprocessing/pre_process_partition.bash $partid $MU_TRANCHES mu &
	fi

	wait

	echo "adding data to $partname, $partid"
	python $BINDIR/../2dload.py add $partid /nfs/exb/zinc22/2dpre_results/s/$partid.pre s
	python $BINDIR/../2dload.py add $partid /nfs/exb/zinc22/2dpre_results/m/$partid.pre m
	python $BINDIR/../2dload.py add $partid /nfs/exb/zinc22/2dpre_results/su/$partid.pre su
	python $BINDIR/../2dload.py add $partid /nfs/exb/zinc22/2dpre_results/mu/$partid.pre mu
done
