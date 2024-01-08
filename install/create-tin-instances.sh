#!/bin/bash
# Copyright (C) 2020 Chinzorig Dandarchuluun, Regents of University of California
# 
# Usage: ./creat-psql-instances.sh /local 1 5
#

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

PSQL_PREFIX="$1"

if [ -z "$3" ]
then
	PSQL_INST_START="1"
	PSQL_INST_END="$2"
else
	PSQL_INST_START="$2"
	PSQL_INST_END="$3"
fi

DEFAULT_PSQL_PORT=5433

for (( i=$PSQL_INST_START; i<=$PSQL_INST_END; i++ ))
do
	dir=$PSQL_PREFIX/psql/12/data$i
	if [[ ! -d $dir ]]; then

		


		mkdir $dir
		chown -R postgres:postgres $dir
		su - postgres -c "/usr/pgsql-12/bin/initdb -D ${dir}"
		new_service="/usr/lib/systemd/system/postgresql${i}-12.service"
		rm -f $new_service
		cp /usr/lib/systemd/system/postgresql-12.service $new_service
		replacement_escaped=$( echo "${dir}" | sed -e 's/[\/&]/\\&/g' )		
		sed -i "31s/.*/Environment=PGDATA=$replacement_escaped/" $new_service
		PSQL_PORT=$(($DEFAULT_PSQL_PORT+$i))
		sed -i "32i Environment=PGPORT=$PSQL_PORT" $new_service
		
		systemctl enable postgresql$i-12
		systemctl start postgresql$i-12
        systemctl restart postgresql$i-12
	 	
		
		PG_HBA_FILE_PATH=$dir/pg_hba.conf
		CONFIG_FILE=$dir/postgresql.conf

		sudo -u postgres -H -- psql -p $PSQL_PORT -c "create database tin;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "create extension intarray;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin < $BINDIR/file.sql

		host=$(hostname | cut -d'.' -f1)	
		port=$PSQL_PORT

		tranches=$(python $BINDIR/get_tranches.py $host $port $BINDIR)	
		tranches=$(echo $tranches | sed -e "s/^\[//" -e "s/\]$//" -e "s/'//g" -e "s/,//g")
		
		echo "Populating tranches table"
		for tranche in $tranches
			do 
				sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "insert into tranches (tranche_name) values ('$tranche');"
			done

		# patch_order=('05_27_2022' 'june3_2022' 'june10_2022' 'catid_partitioned' 'zincid_partitioned' 'partition' 'export')
		# order=('code' 'apply')
		

		# for patch in "${patch_order[@]}"
		# do	
		# 	files=($BINDIR/../psql/tin/patches/$patch/*)
			
		# 	for o in "${order[@]}"
		# 	do
		# 		echo "o: $o"
		# 		# if o.psql exists in files
		# 		file=$BINDIR/../psql/tin/patches/$patch/$o.pgsql
		# 		if [[ " ${files[@]} " =~ " ${file} " ]]; then
		# 			echo "Applying $file"
		# 			sudo -u postgres -H -- psql -p $PSQL_PORT tin -v n_partitions=128 < $file 
		# 		fi
		# 	done
		# done

		# for o in "${order[@]}"
		# do
		# 	echo "o: $o"
		# 	# if o.psql exists in files
		# 	file=$BINDIR/../psql/common/patches/upload/$o.pgsql
		# 	if [ -f "${file}" ]; then
		# 		echo "Applying $file"
		# 		sudo -u postgres -H -- psql -p $PSQL_PORT tin < $file 
		# 	fi
		# done
	

		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO zincread;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO zincwrite;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO zincfree;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO admin;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO adminprivate;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE tin TO tinuser;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "alter role tinuser with superuser;"		
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "ALTER table public.catalog ADD UNIQUE (short_name);"

		sed -i "85i host    tin             tinuser          10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "86i host    tin             zincread         10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "87i host    tin             zincfree         10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "88i host    tin             test             10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "89i host    tin             chembl           10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "90i host    tin             chembl           169.230.0.0/16         password" $PG_HBA_FILE_PATH
		sed -i "91i host    tin             all              10.20.0.0/16           password" $PG_HBA_FILE_PATH
		sed -i "92i host    all             root             10.20.0.31/32          trust" $PG_HBA_FILE_PATH
		
		sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" $CONFIG_FILE
		sudo sed -i "s/^#port = 5432/port = ${PSQL_PORT}/" $CONFIG_FILE

		systemctl restart postgresql$i-12		
		
		echo "######################################## Instance ${i} has been created! ##########################################"
		echo "systemctl status postgresql${i}-12"
		echo ""
	else
    		echo "Skipped creating Instance ${i}. Directory exists! : ${dir}" 1>&2
	fi  
done
