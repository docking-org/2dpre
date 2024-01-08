

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

PSQL_PORT="5440"


patch_order=('05_27_2022' 'june3_2022' 'june10_2022' 'catid_partitioned' 'zincid_partitioned' 'partition' 'export')
order=('code' 'apply')


for patch in "${patch_order[@]}"
do	
    files=($BINDIR/../psql/tin/patches/$patch/*)
    
    for o in "${order[@]}"
    do
        echo "o: $o"
        # if o.psql exists in files
        file=$BINDIR/../psql/tin/patches/$patch/$o.pgsql
        if [[ " ${files[@]} " =~ " ${file} " ]]; then
            echo "Applying $file"
            sudo -u postgres -H -- psql -p $PSQL_PORT tin -v n_partitions=128 < $file 
        fi
    done
done

for o in "${order[@]}"
do
    echo "o: $o"
    # if o.psql exists in files
    file=$BINDIR/../psql/common/patches/upload/$o.pgsql
    if [ -f "${file}" ]; then
        echo "Applying $file"
        sudo -u postgres -H -- psql -p $PSQL_PORT tin < $file 
    fi
done