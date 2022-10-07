import sys, os
import subprocess
import tarfile
import shutil

from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import make_hash_partitions, get_partitions_count, create_transaction_record_table, check_transaction_record, check_transaction_started, upload_complete, increment_version

def create_source_file(database_port, source_dirs, transaction_id):

    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_" + transaction_id + "_upload.txt"
    if os.path.exists(source_f):
        os.remove(source_f)

    try:
        print("processing file for postgres...")
        writemode='w'
        for source_dir in source_dirs:
            for tranche in get_tranches():
                tranche_id = get_tranche_id(tranche)
                src_file = source_dir + '/' + tranche[:3] + '/' + tranche + '.smi'
                print("processing", src_file)
                if not os.path.exists(src_file):
                    src_file += '.gz'
                if not os.path.exists(src_file):
                    continue
                zincid_to_subid_opt(src_file, source_f, tranche_id, writemode=writemode)
                writemode='a'
    except:
        os.remove(source_f)
        raise Exception("unable to create source file!")

    if not os.path.exists(source_f):
        raise Exception("source file not created for some reason?!")
    #psql_source_f.close()
    psql_source_f_t = open(source_f + '.t', 'w')
    # this sed expression converts all backslash groups into double backslashes
    # even if there are 57 backslashes in a row, this will convert them to just 2
    # this is mainly useful for reading in our already exported files, which may have double backslashes in place already
    # we want to make sure we aren't multiplying the backslashes
    # in SMILES strings there shouldn't ever be a natural double backslash, so this should be safe
    subprocess.call(["sed", "-E", "s/[\\\\]+/\\\\\\\\/g", source_f], stdout=psql_source_f_t)
    psql_source_f_t.close()
    os.rename(psql_source_f_t.name, source_f)

    return source_f

def upload_source_f(source_f):
    psql_source_f = open(source_f, 'r')

    code = Database.instance.call("COPY temp_load_p1 FROM STDIN DELIMITER ' '", sp_kwargs={"stdin":psql_source_f})
    if code != 0:
        return False
    return True

def upload_zincid(args):
    database_port = args.port
    source_dirs = args.source_dirs
    diff_dest = args.diff_destination
    transaction_id = args.transaction_id
    database_host = args.host

    if upload_complete(transaction_id):
        print("this upload transaction has already completed!")
        return

    source_f = create_source_file(database_port, source_dirs, transaction_id)

    diffdir = f"{diff_dest}/{transaction_id}/{database_host}:{database_port}"
    #tmpdir = "/local2/load/z22_upload_results/zinc/{}/{}".format(transaction_id, database_port)
    new_substances_f = "{}/newsub.txt".format(diffdir)
    deleted_substances_f = "{}/delsub.txt".format(diffdir)
    substance_conflict_f = "{}/conflict.txt".format(diffdir)

    psqlvars = {
    "source_f" : source_f,
    "new_substances" : new_substances_f,
    "deleted_substances" : deleted_substances_f,
    "substance_conflicts" : substance_conflict_f
    }

    # numerous error cases possible from zinc id upload, meaning of each catalogued in tin_partitioned_zincid_upload.pgsql
    for i in range(1, 7):
        psqlvars["case{}".format(i)] = diffdir + '/' + "case{}".format(i)

    os.system("mkdir -p {}".format(diffdir))
    os.system("chmod 777 {}".format(diffdir))

    code_upload = Database.instance.call_file(BINDIR + "/psql/tin/zincid_upload.pgsql", vars=psqlvars)

    code_sync   = Database.instance.call_file(BINDIR + "/psql/tin/sync_id_tables.pgsql")

    if code_upload == 0 and code_sync == 0:
        increment_version(transaction_id)
        print("upload successfull!")
    elif code_upload == 0 and code_sync != 0:
        increment_version(transaction_id)
        print("upload succeeded, but table sync failed")
    else:
        print("upload failed!")

    os.remove(psqlvars["source_f"])
