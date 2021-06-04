#!/bin/bash

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
LOADBASE=/local2/load
ORIGBASE="/nfs/exb/zinc22/2d /nfs/exb/zinc22/2d-anions"

partition=$1
partition_label=$(grep $partition partitions.txt | awk '{print $1 "_" $2}')

src=$LOADBASE/$partition_label/src

maxidx=0
for tranche in $src/H??????; do

    hval=$(echo $tranche | awk '{print substr($1, 1, 3)}')
    origfiles=""
    for origdir in $(printf "$ORIGBASE" | tr ' ' '\n'); do
        origfiles=$(printf "$origfiles$origdir/$hval/$tranche.smi.gz\n")
    zcat $origfiles > $tranche/orig.smi.gz
    gzip -d $tranche/orig.smi.gz

    python $BINDIR/zincdecode.py $tranche/orig.smi | awk '{print $1 " " $2 " " 1}' > $tranche/orig
    rm $tranche/orig.smi

    awk '{print $1 " " $3 " " 0}' $tranche/subtance.txt > $tranche/curr

    cat $tranche/orig $tranche/curr | sort -k1,1i -k3,3n > $tranche/both
    python $BINDIR/extract_mapping.py $tranche/both
    # orig.new     // entries from original database new to the current database tranche (should be zero, but shouldn't matter if not)
    # curr.new     // entries from current database new to the original database tranche (can be greater than zero)
    # shared       // entries shared by both the current and original database tranches
    # shared.map   // mapping from current sub_id to original sub_id, we will come back to this later
    # max_orig_idx // largest sub_id value from the original database tranche-- 
    #                 whatever the largest of these values is across the entire partition will be the starting id mapping for curr.new entries
    #                 this is perhaps overly cautious, given that the largest sub_id value from the original partition should be == size(original partition)
    #                 in case this isn't true, for whatever reason, we explicitly calculate maximum sub_id to ensure no conflicts
    # curr_lines   // number of lines in curr.new

    p_maxidx=$(cat $tranche/max_orig_idx)
    if [ $p_maxidx -gt $maxidx ]; then
        maxidx=$p_maxidx
    fi
    rm $tranche/max_orig_idx

    rm $tranche/curr
    rm $tranche/both
    rm $tranche/orig
done

curridx=$maxidx

for tranche in $src/H??????; do

    # with the maximum index reached by the original file in hand, we can extend the map to include molecules from curr.new
    awk -v idx=$curridx '{print $2 " " NR+idx}' $tranche/curr.new >> shared.map

    len_curr_new=$(cat $tranche/curr_lines)
    curridx=$((curridx+len_curr_new))

    for archive in $tranche/*.tar.gz; do

        untarred=$(echo "$(basename $archive)" | cut -d'.' -f1-4)
        tar -C $tranche -xzf $(basename $archive)
        gzip -d $tranche/$untarred/sub.gz

        awk '{print $3 " " NR " "'

        python $BINDIR/apply_mapping.py $tranche

done
