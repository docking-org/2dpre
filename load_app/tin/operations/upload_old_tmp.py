import sys, os
import subprocess
import tarfile
import shutil

from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import make_hash_partitions, get_partitions_count, create_transaction_record_table, check_transaction_record, check_transaction_started, increment_version

def find_source_file(source_dir, tranche, ext='.smi'):
    hac = tranche[0:3]
    p1 = os.path.join(source_dir, hac, tranche + ext)
    p2 = os.path.join(source_dir, hac, tranche)
    p3 = os.path.join(source_dir, tranche + ext)
    p4 = os.path.join(source_dir, tranche)
    for p in [p1, p2, p3, p4] + [_p+'.gz' for _p in [p1, p2, p3, p4]]:
        if os.path.isfile(p):
            return p
    return None


def create_source_file(source_dirs, cat_shortnames):

    database_port = Database.instance.port
    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_upload.txt"

    #if os.path.exists(source_f):
    #    return source_f

    psql_source_f = open(source_f, 'w')

    print("processing file for postgres...")
    for source_dir, cat_shortname in zip(source_dirs, cat_shortnames):
        cat_id = get_or_set_catid(cat_shortname)
        for tranche in get_tranches():
            print("processing", tranche)
            tranche_id = get_tranche_id(tranche)

            srcf = find_source_file(source_dir, tranche)

            with open(srcf, 'r') as tf:
                for line in tf:
                    # we do a more sophisticated escape sequence using sed below
                    # this strategy could potentially add extra escape characters when they are not needed
                    #escaped_line = line.replace('\\', '\\\\').strip()
                    tokens = line.split()
                    if len(tokens) == 2: # filter out lines that will cause an error to be thrown
                        psql_source_f.write(' '.join(tokens + [str(cat_id), str(tranche_id)]) + "\n")

    psql_source_f.close() 
    subprocess.call(["chmod", "777", source_f])
    psql_source_f_t = open(source_f + '.t', 'w')
    subprocess.call(["sed", "-E", "s/\\\\/\\\\\\\\/g", psql_source_f.name], stdout=psql_source_f_t)
    #subprocess.call(["sed", "-E", "s/([^\\\\]+|^)(\\\\){1}([^\\\\]+|$)/\\1\\2\\2\\3/g", psql_source_f.name], stdout=psql_source_f_t)
    psql_source_f_t.close()
    os.rename(psql_source_f_t.name, psql_source_f.name)
    return source_f

def partition_and_upload_input_data(source_dirs, cat_shortnames):

    source_f = create_source_file(source_dirs, cat_shortnames)
    n_partitions = get_partitions_count()

    Database.instance.call("drop table if exists temp_load_p1")
    Database.instance.call("create table temp_load_p1 (smiles varchar, code varchar, cat_id smallint, tranche_id smallint) partition by hash(smiles)")
    make_hash_partitions("temp_load_p1", n_partitions)

    Database.instance.call("drop table if exists temp_load_p2");
    Database.instance.call("create table temp_load_p2 (sub_id bigint, code varchar, cat_id smallint, tranche_id smallint) partition by hash(code)")
    make_hash_partitions("temp_load_p2", n_partitions)

    Database.instance.call("drop table if exists temp_load_p3");
    Database.instance.call("create table temp_load_p3 (sub_id bigint, code_id bigint, tranche_id smallint) partition by hash(sub_id)")
    make_hash_partitions("temp_load_p3", n_partitions)

    source_file = open(source_f, 'r')
    code = Database.instance.call("copy temp_load_p1(smiles, code, cat_id, tranche_id) from STDIN delimiter ' '", sp_kwargs={"stdin" : source_file})
    if not code == 0:
        raise NameError("failed to copy in data!")

    Database.instance.call("analyze temp_load_p1")
    Database.instance.call("analyze temp_load_p2")
    Database.instance.call("analyze temp_load_p3")

    return n_partitions

def upload_partitioned(stage, partition_index, transaction_identifier, diff_destination):

    psqlvars = {}
    psqlvars["stage"] = stage
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier
    psqlvars["diff_file_dest"] = diff_destination

    code = Database.instance.call_file(BINDIR + '/psql/tin/upload.pgsql', vars=psqlvars)
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(stage, partition_index))

#def get_partitions_count():
#    return int(Database.instance.select("select ivalue from meta where svalue = 'n_partitions'").first()[0])

def emulate_upload(args):

    source_dirs = args.source_dirs.split(',')
    cat_shortnames = args.transaction_id.split('.')
    diff_destination = args.diff_destination

    transaction_identifier = "_".join(cat_shortnames + (["update"] if args.just_update_info else []))
    diff_destination = diff_destination + "/{}/{}".format(transaction_identifier, args.host+':'+str(args.port))
    diff_buckets = ["/sub", "/cat", "/catsub"] if not args.just_update_info else ["/sub_update_tranche_id", "/sup_update_cat_id"]
    diff_locations =  [diff_destination + diff_bucket for diff_bucket in diff_buckets]
    if args.fake_upload:
        increment_version(transaction_identifier)
        return True

    subprocess.call(["mkdir", "-p"] + diff_locations)
    subprocess.call(["chmod", "777"] + diff_locations)
    
    n_partitions = get_partitions_count()

    if args.just_update_info:
        source_f = create_source_file(args.source_dirs, args.catalogs)
        code = Database.instance.call_file(BINDIR + '/psql/tin/upload_update.pgsql', vars={"source_f":source_f, "diff_destination":diff_destination})
        if code == 0:
            increment_version(transaction_identifier)
        return True

    if not check_transaction_started(transaction_identifier):
        partition_and_upload_input_data(source_dirs, cat_shortnames)
        if not create_transaction_record_table(transaction_identifier):
            return False

    for i in range(n_partitions):
        print(1, i)
        if check_transaction_record(transaction_identifier, 1, i):
            continue
        upload_partitioned(1, i, transaction_identifier, diff_destination)
    for i in range(n_partitions):
        print(2, i)
        if check_transaction_record(transaction_identifier, 2, i):
            continue
        upload_partitioned(2, i, transaction_identifier, diff_destination)
    for i in range(n_partitions):
        print(3, i)
        if check_transaction_record(transaction_identifier, 3, i):
            continue
        upload_partitioned(3, i, transaction_identifier, diff_destination)

    increment_version(transaction_identifier)

    return True
