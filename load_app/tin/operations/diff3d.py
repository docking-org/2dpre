import sys, os
import subprocess
import tarfile
import shutil

from load_app.common.consts import *
from load_app.tin.common import *
from load_app.tin.operations.upload import find_source_file
from load_app.common.upload import make_hash_partitions, get_partitions_count, create_transaction_record_table, check_transaction_record, check_transaction_started, upload_complete, increment_version

def create_source_file(database_port, source_dirs, transaction_id, args):

    source_f = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_" + transaction_id + "_upload.txt"
    if os.path.exists(source_f):
        if args.debug:
            return source_f
        os.remove(source_f)

    try:
        print("processing file for postgres...")
        writemode='w'
        for source_dir in source_dirs:
            for tranche in get_tranches():
                tranche_id = get_tranche_id(tranche)
                #src_file = find_source_file(source_dir, tranche, ext='.txt')
                src_file = source_dir + '/' + tranche[:3] + '/' + tranche + '.txt'
                print("processing", src_file)
                if not src_file:
                    continue
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
        print("source for postgres due to empty source files, going to create an empty file!")
        with open(source_f, 'w') as sf:
            pass
        #raise Exception("source file not created for some reason?!")
    #psql_source_f.close()
    #psql_source_f_t = open(source_f + '.t', 'w')
    # this sed expression converts all backslash groups into double backslashes
    # even if there are 57 backslashes in a row, this will convert them to just 2
    # this is mainly useful for reading in our already exported files, which may have double backslashes in place already
    # we want to make sure we aren't multiplying the backslashes
    # in SMILES strings there shouldn't ever be a natural double backslash, so this should be safe
    #subprocess.call(["sed", "-E", "s/[\\\\]+/\\\\\\\\/g", source_f], stdout=psql_source_f_t)
    #psql_source_f_t.close()
    #os.rename(psql_source_f_t.name, source_f)

    return source_f

#def upload_source_f(source_f):
#    psql_source_f = open(source_f, 'r')
#
#    code = Database.instance.call("COPY temp_load_p1 FROM STDIN DELIMITER ' '", sp_kwargs={"stdin":psql_source_f})
#    if code != 0:
#        return False
#    return True

def diff3d(args):
    database_port = args.port
    source_dirs = args.source_dirs.split(',')
    diff_dest = args.diff_destination
    transaction_id = args.transaction_id
    database_host = args.host
    tarball_ids = args.tarball_ids

    #if args.fake_upload:
    #    increment_version(transaction_id)
    #    return True

    if  upload_complete(transaction_id):
        print("this upload transaction has already completed!")
        return

    source_f = create_source_file(database_port, source_dirs, transaction_id, args)

    diffdir = f"{diff_dest}/{transaction_id}/{database_host}:{database_port}"

    psqlvars = {
    "source_f" : source_f,
    "tarball_f" : tarball_ids,
    "diff_dest" : diffdir
    }

    os.system("mkdir -p {}".format(diffdir))
    os.system("chmod 777 {}".format(diffdir))

    code_diff = Database.instance.call_file(BINDIR + "/psql/tin/zinc_3d_diff.pgsql", vars=psqlvars)

    if code_diff == 0:
        increment_version(transaction_id)
        print("diff successfull!")
    else:
        print("diff failed!")

    if not args.debug:
        os.remove(psqlvars["source_f"])
