import sys, os
import subprocess
import tarfile
import shutil

from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import make_hash_partitions, get_partitions_count, create_transaction_record_table, check_transaction_record, check_transaction_started

def create_source_file(database_port, source_dirs, transaction_id):

    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_" + transaction_id + "_upload.txt"
    if os.path.exists(source_f):
        return source_f

    print("processing file for postgres...")
    for source_dir in source_dirs:
        for tranche in get_tranches(database_port):
            print("processing", tranche)
            tranche_id = get_tranche_id(database_port, tranche)
            src_file = source_dir + '/' + tranche[:3] + '/' + tranche + '.smi'
            if not os.path.exists(src_file):
                continue
            zincid_to_subid_opt(src_file, source_f, tranche_id, 1, writemode='a')

    #psql_source_f.close()
    psql_source_f_t = open(source_f + '.t', 'w')
    # this sed expression won't convert any escape sequences that are already double escaped e.g \ -> \\ but \\ -> \\
    # it also won't convert triple, quadruple, etc. escape, just single escape. Hopefully there are very few smiles with \\+ as a legitimate part of their structure
    subprocess.call(["sed", "-E", "s/([^\\\\]+|^)(\\\\){1}([^\\\\]+|$)/\\1\\2\\2\\3/g", source_f], stdout=psql_source_f_t)
    psql_source_f_t.close()
    os.rename(psql_source_f_t.name, source_f)

    return source_f

def upload_source_f(source_f):
    psql_source_f = open(source_f, 'r')

    code = Database.instance.call("COPY temp_load_p1 FROM STDIN DELIMITER ' '", sp_kwargs={"stdin":psql_source_f})
    if code != 0:
        return False
    return True

def upload_zincid(database_port, source_dirs, transaction_id):

    if upload_complete(database_port, transaction_id):
        print("this upload transaction has already completed!")
        return

    source_f = create_source_file(database_port, source_dirs, transaction_id)

    tmpdir = "/local2/load/z22_upload_results/zinc/{}/{}".format(transaction_id, database_port)
    new_substances_f = "{}/newsub.txt".format(tmpdir)
    deleted_substances_f = "{}/delsub.txt".format(tmpdir)
    substance_conflict_f = "{}/conflict.txt".format(tmpdir)

    psqlvars = {
    "source_f" : source_f,
    "new_substances" : new_substances_f,
    "deleted_substances" : deleted_substances_f,
    "substance_conflicts" : substance_conflict_f
    }

    # numerous error cases possible from zinc id upload, meaning of each catalogued in tin_partitioned_zincid_upload.pgsql
    for i in range(1, 7):
        psqlvars["case{}".format(i)] = tmpdir + '/' + "case{}".format(i)

    # i fucked up and deployed a version of this procedure with errors, so now I have to roll them back once
    # will delete this section once the mistake has been eradicated
    if not get_patched(database_port, 'whoops1'):
        if not os.path.exists(tmpdir):
            set_patched(database_port, 'whoops1', True)
        else:
            if not os.path.exists(new_substances_f) or not os.path.exists(deleted_substances_f) or not os.path.exists(substance_conflict_f):
                code = 0
            else:
                code = Databse.instance.call_file(BINDIR + '/psql/fix_crappy_mistake_onetime.pgsql', vars=psqlvars)
            if code == 0:
                set_patched(database_port, 'whoops1', True)
                Database.instance.call("delete from meta where varname = 'upload_name' and svalue = '{}'".format(transaction_id))
            else:
                raise NameError("unable to fix whoops1!")

    os.system("mkdir -p {}".format(tmpdir))
    os.system("chmod 777 {}".format(tmpdir))

    code = Database.instance.call_file(BINDIR + "/psql/tin_partitioned_zincid_upload.pgsql", vars=psqlvars)

    if code == 0:
        increment_version(database_port, transaction_id)
        print("upload successfull!")

    os.remove(psqlvars["source_f"])
