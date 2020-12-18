#!/bin/bash
# in: JOB_ID, TASK_ID, SOURCE, DEST, BINPATH

source /nfs/soft/mitools/env.sh
#source /mnt/nfs/home/devtest/anaconda3/bin/activate 
export PATH=$PATH:/nfs/soft/www/apps/tin01/envs/development/bin
export LD_LIBRARY_PATH="/usr/pgsql-12/lib:/usr/local/lib64"
JOB_ID=$SLURM_ARRAY_JOB_ID
TASK_ID=$SLURM_ARRAY_TASK_ID

echo $JOB_ID $TASK_ID

mkdir -p /dev/shm/2dpre/${JOB_ID}_${TASK_ID}
pushd $BINPATH
BINPATH=$PWD
popd
cd /dev/shm/2dpre/${JOB_ID}_${TASK_ID}
TARGET=$(ls $SOURCE | awk -v x="$SOURCE/" '{print x $1 " " NR}' | grep -w $TASK_ID | awk '{print $1}')
echo "$(hostname)  ${JOB_ID}_${TASK_ID} $TARGET" > info
ln -s $TARGET $(basename $TARGET)

$BINPATH/zincload-catalog.sh --skip-resolution --skip-creation --skip-loading --skip-depletion --name working $(basename $TARGET)

tail -n+2 working/23-selected-compounds.ism > $DEST/$(basename $TARGET)
rm -r /dev/shm/2dpre/${JOB_ID}_${TASK_ID}
