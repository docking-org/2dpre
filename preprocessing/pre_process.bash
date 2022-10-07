#!/bin/bash
# in: JOB_ID, TASK_ID, SOURCE, DEST, BINPATH

#function synchronize_all_but_first {
#        if [ -f /tmp/${1}.done ]; then
#                if [ $(( (`date +%s` - `stat -L --format %Y /tmp/${1}.done`) > (10) )) ]; then
#                        rm /tmp/${1}.done
#                else
#                        return;
#                fi
#        fi # in the case of a particularly short running command, it might be done by the time another job even enters this function
#        flock -n /tmp/${1}.lock -c "printf ${1} && ${@:2} && echo > /tmp/${1}.done" && FIRST=TRUE
#        if [ -z $FIRST ]; then
#                printf "waiting ${1}"
#                n=0
#                while ! [ -f /tmp/${1}.done ]; do sleep 0.1; n=$((n+1)); if [ $n -eq 10 ]; then printf "."; n=0; fi; done
#        else
#                sleep 1 && rm /tmp/${1}.done
#        fi
#        echo
#}

#old_work=$(find /scratch/2dpre_$(whoami) -type d -mtime +180 | wc -l)
#if [ $old_work -ge 1 ]; then
#	synchronize_all_but_first "removing_old_work" "find /scratch/2dpre_$(whoami) -type d -mtime +180 | xargs rm -r"
#fi

# make sure any error generates an error exit code, don't want our scripts to think this job succeeded if it hasn't
set -e

source /nfs/soft/mitools/env.sh
#source /mnt/nfs/home/devtest/anaconda3/bin/activate 
export PATH=$PATH:/nfs/soft/www/apps/tin01/envs/development/bin
export LD_LIBRARY_PATH="/usr/pgsql-12/lib:/usr/local/lib64"
JOB_ID=$SLURM_ARRAY_JOB_ID
TASK_ID=$SLURM_ARRAY_TASK_ID

echo $JOB_ID $TASK_ID
echo $HOSTNAME
WORKDIR=/scratch/2dpre_$(whoami)/${JOB_ID}_${TASK_ID}
mkdir -p $WORKDIR

# trying something new here
trap 'rm -rf -- "$WORKDIR"' EXIT

pushd $BINPATH
BINPATH=$PWD
popd
cd $WORKDIR
TARGET=$(ls $SOURCE | awk -v x="$SOURCE/" '{print x $1 " " NR}' | grep -w $TASK_ID | awk '{print $1}')
echo "$(hostname)  ${JOB_ID}_${TASK_ID} $TARGET" > info
ln -s $TARGET $(basename $TARGET)

$BINPATH/zincload-catalog.sh --skip-resolution --skip-creation --skip-loading --skip-depletion --name working $(basename $TARGET)

tail -n+2 working/23-selected-compounds.ism > $DEST/$(basename $TARGET)
[ -z $SKIP_DELETE] && rm -r /scratch/2dpre_$(whoami)/${JOB_ID}_${TASK_ID}
