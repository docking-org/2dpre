#! /bin/bash -f


if [ "$#" -ne 3 ]; then
	echo "Usage : bash zinc22_full_catalog_map.bash <PRE_DIR> <SUB_EXPORT_DIR> <EXPORT_DIR>" && exit
fi

export PRE_DIR=$1
export SUB_EXPORT_DIR=$2
export EXPORT_DIR=$3
mkdir -pv $EXPORT_DIR

task_num=$(ls $PRE_DIR | wc -l )
sbatch  -J z22_cat_export -o /nfs/home/khtang/store/informer_logs/%A_%a.log --array=1-$task_num%10 /nfs/home/khtang/code/TIN_Scripts/export_supplier_code/get_zinc22_ids.bash 
