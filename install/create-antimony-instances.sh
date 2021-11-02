#!/bin/bash
# Copyright (C) 2020 Chinzorig Dandarchuluun, Regents of University of California
# 
# Usage: ./create-antimony-instances.sh /local 1 5
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

# start of port numbering for antimony instances
DEFAULT_PSQL_PORT=5533

for (( i=$PSQL_INST_START; i<=$PSQL_INST_END; i++ ))
do
	dir=$PSQL_PREFIX/psql/12/data_sb$i
	if [[ ! -d $dir ]]; then
		mkdir $dir
		chown -R postgres:postgres $dir
		su - postgres -c "/usr/pgsql-12/bin/initdb -D ${dir}"
		new_service="/usr/lib/systemd/system/postgresql${i}sb-12.service"
		rm -f $new_service
		cp /usr/lib/systemd/system/postgresql-12.service $new_service
		replacement_escaped=$( echo "${dir}" | sed -e 's/[\/&]/\\&/g' )		
		sed -i "31s/.*/Environment=PGDATA=$replacement_escaped/" $new_service
		PSQL_PORT=$(($DEFAULT_PSQL_PORT+$i))
		sed -i "32i Environment=PGPORT=$PSQL_PORT" $new_service
		
		systemctl enable postgresql${i}sb-12
		systemctl start postgresql${i}sb-12
                systemctl restart postgresql${i}sb-12
	 	
		
		PG_HBA_FILE_PATH=$dir/pg_hba.conf
		CONFIG_FILE=$dir/postgresql.conf

		sudo -u postgres -H -- psql -p $PSQL_PORT -c "create database antimony;"
		#sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "create extension rdkit;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "create extension intarray;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin < $BINDIR/antimony.sql
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO zincread;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO zincwrite;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO zincfree;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO admin;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO adminprivate;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "GRANT CONNECT ON DATABASE antimony TO tinuser;"
		sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "alter role tinuser with superuser;"		
		#sudo -u postgres -H -- psql -p $PSQL_PORT tin -c "ALTER table public.catalog ADD UNIQUE (short_name);"

		sed -i "85i host    antimony             tinuser          10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "86i host    antimony             zincread         10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "87i host    antimony             zincfree         10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "88i host    antimony             test             10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "89i host    antimony             chembl           10.20.0.0/16           trust" $PG_HBA_FILE_PATH
		sed -i "90i host    antimony             chembl           169.230.0.0/16         password" $PG_HBA_FILE_PATH
		sed -i "91i host    antimony             all              10.20.0.0/16           password" $PG_HBA_FILE_PATH
		sed -i "92i host    all             root             10.20.0.31/32          trust" $PG_HBA_FILE_PATH
		
		sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" $CONFIG_FILE
		sudo sed -i "s/^#port = 5432/port = ${PSQL_PORT}/" $CONFIG_FILE

		systemctl restart postgresql${i}sb-12		
		
		echo "######################################## Instance ${i}sb has been created! ##########################################"
		echo "systemctl status postgresql${i}sb-12"
		echo ""
	else
    		echo "Skipped creating Instance ${i}sb. Directory exists! : ${dir}" 1>&2
	fi  
done
