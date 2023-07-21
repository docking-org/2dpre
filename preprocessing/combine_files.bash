#!/bin/bash

src_file=$1
src_entry=$(head -n $SLURM_ARRAY_TASK_ID $src_file | tail -n 1)
comb_src=$(echo $src_entry | awk '{print $1}')
comb_dst=$(echo $src_entry | awk '{print $2}')

cat $comb_src/* > $comb_dst
