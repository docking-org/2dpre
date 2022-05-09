import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

def create_source_file(database_port, source_dirs, cat_shortnames):

    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_upload.txt"

    psql_source_f = open(source_f, 'w')

    print("processing file for postgres...")
    for source_dir, cat_shortname in zip(source_dirs, cat_shortnames):
        cat_id = get_or_set_catid(database_port, cat_shortname)
        for tranche in get_tranches(database_port):
            print("processing", tranche)
            tranche_id = get_tranche_id(database_port, tranche)

            with open(source_dir + '/' + tranche, 'r') as tf:
                for line in tf:
                    # we do a more sophisticated escape sequence using sed below
                    # this strategy could potentially add extra escape characters when they are not needed
                    #escaped_line = line.replace('\\', '\\\\').strip()
                    tokens = escaped_line.split()
                    if len(tokens) == 2: # filter out lines that will cause an error to be thrown
                        psql_source_f.write(' '.join(tokens + [str(cat_id), str(tranche_id)]) + "\n")

    psql_source_f.close() 
    psql_source_f_t = open(source_f + '.t', 'w')
    subprocess.call(["sed", "-E", "s/([^\\\\]+|^)(\\\\){1}([^\\\\]+|$)/\\1\\2\\2\\3/g", psql_source_f.name], stdout=psql_source_f_t)
    psql_source_f_t.close()
    os.rename(psql_source_f_t.name, psql_source_f.name)
    return source_f

"""
def upload(database_port, source_dirs, cat_shortnames):

    #source_f = sys.argv[3]
    #cat_shortname = sys.argv[4]

    #for source_f in source_files:
    #    if not os.path.isfile(source_f):
    #        print("file to upload does not exist!", source_f)
    #        sys.exit(1)
    #    elif not source_f.endswith(".pre"):
    #        print("expects a .pre file!")
    #        sys.exit(1)

    psqlvars = {
        "source_f" : None,
        "sb_count" : 0,
        "cc_count" : 0,
        "cs_count" : 0
    }

    psqlvars["source_f"] = create_source_file(database_port, source_dirs, cat_shortnames)
    psqlvars["sb_count"] = int(call_psql(database_port, cmd="select nextval('sub_id_seq')", getdata=True)[1][0])
    psqlvars["cc_count"] = int(call_psql(database_port, cmd="select nextval('cat_content_id_seq')", getdata=True)[1][0])
    psqlvars["cs_count"] = int(call_psql(database_port, cmd="select nextval('cat_sub_itm_id_seq')", getdata=True)[1][0])

    code = call_psql(database_port, vars=psqlvars, psqlfile=BINDIR + "/psql/tin_partitioned_upload.pgsql")

    if code == 0:
        increment_version(database_port, ','.join(cat_shortnames))
        print("upload successfull!")

    #os.remove(psql_source_f.name)
"""

def make_hash_partitions(database_port, table_name, N):

    code = 0
    for i in range(N):
        code |= call_psql(database_port, cmd="create table {0}_p{1} partition of {0} for values with (modulus {2}, remainder {1})".format(table_name, i, N))
        if code != 0:
            raise NameError("failed to create hash partitions for {}:{}:{}".format(database_port, table_name, N))
            return False
    return True

def get_partitions_count(database_port):
    n_partitions = int(call_psql(database_port, cmd="select ivalue from tin_meta where svalue = 'n_partitions' limit 1", getdata=True)[1][0])
    return n_partitions

def partition_and_upload_input_data(database_port, source_dirs, cat_shortnames):

    source_f = create_source_file(database_port, source_dirs, cat_shortnames)
    n_partitions = get_partitions_count(database_port)

    call_psql(database_port, cmd="drop table if exists temp_load_p1");
    call_psql(database_port, cmd="create table temp_load_p1 (smiles varchar, code varchar, cat_id smallint, tranche_id smallint) partition by hash(smiles)")
    make_hash_partitions(database_port, "temp_load_p1", n_partitions)

    call_psql(database_port, cmd="drop table if exists temp_load_p2");
    call_psql(database_port, cmd="create table temp_load_p2 (sub_id bigint, code varchar, cat_id smallint, tranche_id smallint) partition by hash(code)")
    make_hash_partitions(database_port, "temp_load_p2", n_partitions)

    call_psql(database_port, cmd="drop table if exists temp_load_p3");
    call_psql(database_port, cmd="create table temp_load_p3 (sub_id bigint, code_id bigint, tranche_id smallint) partition by hash(sub_id)")
    make_hash_partitions(database_port, "temp_load_p3", n_partitions)

    source_file = open(source_f, 'r')
    code = call_psql(database_port, cmd="copy temp_load_p1 from STDIN delimiter ' '", stdin=source_file)
    if not code == 0:
        raise NameError("failed to copy in data!")

    call_psql(database_port, cmd="analyze temp_load_p1")
    call_psql(database_port, cmd="analyze temp_load_p2")
    call_psql(database_port, cmd="analyze temp_load_p3")

    return n_partitions

def create_transaction_record_table(database_port, transaction_identifier):

    code = call_psql(database_port, cmd="create table if not exists transaction_record_{} (stagei int, parti int, nupload int, nnew int)".format(transaction_identifier))
    code |= call_psql(database_port, cmd="insert into transaction_record_{} (values (-1, -1, 0, 0))".format(transaction_identifier))

    if code == 0:
        return True
    return False

def check_transaction_record(database_port, transaction_identifier, stagei, parti):

    data = call_psql(database_port, cmd="select * from transaction_record_{} where parti = {} and stagei = {}".format(transaction_identifier, parti, stagei), getdata=True)

    if len(data) > 1:
        return True
    return False

def check_transaction_started(database_port, transaction_identifier):
    return check_transaction_record(database_port, transaction_identifier, -1, -1)

#def initialize_partitioned_upload(database_port, source_dirs, cat_shortnames):

#    partition_and_upload_input_data(database_port, source_dirs, cat_shortnames)

def upload_partitioned_part1_substances(database_port, partition_index, transaction_identifier):

    psqlvars = {}
    psqlvars["stage"] = 1
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier

    code = call_psql(database_port, vars=psqlvars, psqlfile=BINDIR + '/psql/tin_partitioned_upload.pgsql')
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(1, partition_index))

def upload_partitioned_part2_catcontents(database_port, partition_index, transaction_identifier):

    psqlvars = {}
    psqlvars["stage"] = 2
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier

    code = call_psql(database_port, vars=psqlvars, psqlfile=BINDIR + '/psql/tin_partitioned_upload.pgsql')
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(2, partition_index))

def upload_partitioned_part3_catsubstances(database_port, partition_index, transaction_identifier):

    psqlvars = {}
    psqlvars["stage"] = 3
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier

    code = call_psql(database_port, vars=psqlvars, psqlfile=BINDIR + '/psql/tin_partitioned_upload.pgsql')
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(3, partition_index))

def emulate_upload(database_port, source_dirs, cat_shortnames):

    transaction_identifier = "_".join(cat_shortnames)
    
    n_partitions = get_partitions_count(database_port)

    if not check_transaction_started(database_port, transaction_identifier):
        partition_and_upload_input_data(database_port, source_dirs, cat_shortnames)
        if not create_transaction_record_table(database_port, transaction_identifier):
            return False

    # technically I don't need to separate the 3 upload parts into separate functions, its just a difference in the "stage" variables value
    # for clarity I think this is best however
    for i in range(n_partitions):
        print(1, i)
        if check_transaction_record(database_port, transaction_identifier, 1, i):
            continue
        upload_partitioned_part1_substances(database_port, i, transaction_identifier)
    for i in range(n_partitions):
        print(2, i)
        if check_transaction_record(database_port, transaction_identifier, 2, i):
            continue
        upload_partitioned_part2_catcontents(database_port, i, transaction_identifier)
    for i in range(n_partitions):
        print(3, i)
        if check_transaction_record(database_port, transaction_identifier, 3, i):
            continue
        upload_partitioned_part3_catsubstances(database_port, i, transaction_identifier)

    return True
