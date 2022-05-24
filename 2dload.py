import argparse
import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.operations.upload import emulate_upload as tin_upload
from load_app.tin.operations.upload_zincid import upload_zincid as tin_upload_zincid
from load_app.tin.operations.export_antimony import export_all_from_tin as tin_antimony_export
from load_app.tin.operations.export_vendors import export_vendors as tin_export_vendors
from load_app.tin.operations.export_substances import export_substances as tin_export_substances
from load_app.antimony.operations.upload import emulate_upload as antimony_upload

from load_app.tin.patches.partition import TinPartitionPatch
from load_app.tin.patches.catid import CatIdPartitionPatch
from load_app.tin.patches.zincid import ZincIdPartitionPatch
from load_app.tin.patches.export import ExportPatch

from load_app.antimony.patches.partition import AntimonyPartitionPatch

from load_app.common.patch import PatchPatch, UploadPatch
from load_app.common.database import Database
from load_app.common.upload import upload_complete

from load_app.tin.upload_hist import check_upload_history as tin_check_upload_history 

import fcntl

import argparse

def checkpatch(patchcls):
    patchobj = patchcls()
    if patchobj.is_patched():
        return
    else:
        print("patching: {}".format(patchcls.__name__))
        patchobj.apply()
        print("done patching: {}".format(patchcls.__name__))

def checktinpatches(args):
    checkpatch(PatchPatch)
    checkpatch(UploadPatch)
    checkpatch(TinPartitionPatch)
    checkpatch(ZincIdPartitionPatch)
    checkpatch(CatIdPartitionPatch)
    checkpatch(ExportPatch)
def checktinuptodate(args):
    catalogs = getattr(args, 'catalogs', None)
    transaction_id = getattr(args, 'transaction_id', None)
    if catalogs:
        transaction_id = '_'.join(catalogs)
    if upload_complete(transaction_id):
        raise Exception("this upload has already finished for this database!")
    tin_check_upload_history(transaction_id)

def checksbpatches(args):
    checkpatch(PatchPatch)
    checkpatch(UploadPatch)
    checkpatch(AntimonyPartitionPatch)
def checksbuptodate(args):
    pass

def tin_export(args):
    if args.export_type == "substance":
        tin_export_substances(args.export_dest)
    elif args.export_type == "vendors":
        tin_export_vendors(args.export_dest)
    elif args.export_type == "antimony":
        tin_antimony_export()

# this function is basically a comment
# difficult to think of a succinct name for something weird like creating a function that returns a lambda that strings multiple functions together
# just so I'm not writing a thesaurus on each line I use it I will alias it to "wrpfnc"
def wrap_functions_for_sequential_execution(*f):
    return lambda args : [e(args) for e in f[:]]
def wrpfnc(*f):
    return wrap_functions_for_sequential_execution(*f)

parser_main = argparse.ArgumentParser()
parser_main.add_argument("port", type=int, help="database port to connect @")
# we want the host's "short" name, so remove the .cluster.bkslab etc..
thishost = os.uname()[1].split(".")[0]
parser_main.add_argument("--host", type=str, help="machine hostname", default=thishost)
#parser_main.set_defaults(func=lambda args: None)

system_subparser = parser_main.add_subparsers(title="subsystem", help="choose a subsystem")

parser_tin = system_subparser.add_parser("tin", help="tin subsystem, see 2dload.py [port] tin --help", aliases=["sn"])
parser_tin.set_defaults(subsystem="tin")

tin_ops_subparser = parser_tin.add_subparsers(title="operation", help="choose an operation")

tin_patch_parser = tin_ops_subparser.add_parser("patch", help="just patch database")
tin_patch_parser.set_defaults(func=wrpfnc(checktinpatches, checktinuptodate))

tin_upload_parser = tin_ops_subparser.add_parser("upload", help="upload pre-processed vendor data to database")
tin_upload_parser.add_argument("--source_dirs", nargs="+", required=True, help="directory(s) where tranche split & preprocessed files are stored")
tin_upload_parser.add_argument("--catalogs", nargs="+", required=True, help="name(s) of catalogs being uploaded, each corresponding to a source directory at the same position within the argument list")
tin_upload_parser.add_argument("--diff_destination", required=True, help="where to export the database diff from this upload to")
tin_upload_parser.set_defaults(func=wrpfnc(checktinpatches, checktinuptodate, tin_upload))

tin_upload_zincid_parser = tin_ops_subparser.add_parser("upload_zincid", help="upload existing zinc id annotated molecules to database, replacing existing ones or adding aliases where appropriate")
tin_upload_zincid_parser.add_argument("source_dirs", nargs="+", help="directory(s) where zinc id & tranche split annotated files are stored")
tin_upload_zincid_parser.add_argument("transaction_id", help="name of transaction for record keeping and synchronization with other databases")
tin_upload_zincid_parser.set_defaults(func=wrpfnc(checktinpatches, checktinuptodate, tin_upload_zincid))

tin_export_parser = tin_ops_subparser.add_parser("export", help="export database to disk")
tin_export_parser.add_argument("export_type", choices=["substance", "vendors", "antimony"], help="choose to export substance+zincids (substance), substance+codes+zincids (vendors), or codes+codeids (antimony))")
tin_export_parser.add_argument("export_dest", default=None, help="where exported files should be sent (hardcoded for antimony)")
tin_export_parser.set_defaults(func=wrpfnc(checktinpatches, checktinuptodate, tin_export), user="tinuser")

parser_sb = system_subparser.add_parser("antimony", help="antimony subsystem, see 2dload.py [port] antimony --help", aliases=["sb"])
parser_sb.set_defaults(subsystem="antimony")

sb_ops_subparser = parser_sb.add_subparsers(title="operation", help="choose an operation")

sb_upload_parser = sb_ops_subparser.add_parser("upload", help="upload exported supplier code data to antimony")
sb_upload_parser.add_argument("transaction_id", help="unique name for this transaction. apply this name to all databasese you are uploading to in the same time frame")
sb_upload_parser.add_argument("diff_destination", help="where to put database diff")
sb_upload_parser.set_defaults(func=wrpfnc(checksbpatches, checksbuptodate, antimony_upload))

args = parser_main.parse_args()
print(args)
Database.set_instance(args.host, args.port, args.subsystem + 'user', args.subsystem)

lockf_location = "/tmp/zinc22_pg_{}.lock".format(args.port)
if not os.path.exists(lockf_location):
    os.system("touch {}".format(lockf_location))
lockf = open(lockf_location, 'r')

try:
    fcntl.flock(lockf.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except:
    print("Process already using database!")
    lockf.close()
    sys.exit(1)

try:
    args.func(args)
finally:
    fcntl.flock(lockf.fileno(), fcntl.LOCK_UN)
    lockf.close()

sys.exit(0)

"""
if len(sys.argv) == 1:
    print("usages:")
    print("2dload.py [port] tin upload [source_dir] [transaction id]")
    print("       ----> uploads appropriate tranches in source_dir to tin database @ port")
    print("       ----> example:")
    print("       ----> 2dload_new.py 5434 tin upload /nfs/exb/zinc22/2dpre_results/s s")
    print()
    print("2dload.py [port] tin")
    print("       ----> applies pending patches to tin database @ port without doing anything else")
    print()
    print("2dload.py [port] tin upload_zincid [source_dir] [transaction id]")
    print("       ----> upload zinc ids to database, inserting any missing zinc ids and recording any conflicts")
    print()
    sys.exit(0)
"""

# begin main functionality
database_port = int(sys.argv[1])
chosen_db = sys.argv[2]
chosen_mode = "none" if len(sys.argv) < 4 else sys.argv[3]
args = sys.argv[4:]
hostname = os.getenv("HOST_OVERRIDE") or os.uname()[1].split(".")[0]

lockf_location = "/tmp/zinc22_pg_{}.lock".format(database_port)
if not os.path.exists(lockf_location):
    os.system("touch {}".format(lockf_location))
lockf = open(lockf_location, 'r')

try:
    lockf_location = "/tmp/zinc22_pg_{}.lock".format(database_port)
    if not os.path.exists(lockf_location):
        os.system("touch {}".format(lockf_location))
    lockf = open(lockf_location, 'r')

    try:
        fcntl.flock(lockf.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except:
        print("Process already using database!")
        lockf.close()
        sys.exit(1)

    if chosen_db == "tin":

        Database.set_instance(hostname, database_port, 'tinuser', 'tin')

        checkpatch(PatchPatch)
        checkpatch(UploadPatch)
        checkpatch(TinPartitionPatch)
        checkpatch(ZincIdPartitionPatch)
        checkpatch(CatIdPartitionPatch)
        checkpatch(ExportPatch)

        if chosen_mode == "upload":
            source_files = args[0].replace(',', ' ').split()
            cat_shortnames = args[1].replace(',', ' ').split()
            tin_upload(source_files, cat_shortnames)

        if chosen_mode == "upload_zincid":
            source_dirs = args[0].split(',')
            transaction_id = args[1]
            tin_upload_zincid(source_dirs, transaction_id)


        if chosen_mode == "export_vendors":
            dest = args[0]
            tin_export_vendors(dest)

        if chosen_mode == "export_antimony":
            export_antimony_from_tin()

    if chosen_db == "antimony":

        Database.set_instance(hostname, database_port, 'antimonyuser', 'antimony')

        checkpatch(PatchPatch)
        checkpatch(UploadPatch)
        checkpatch(AntimonyPartitionPatch)

        if chosen_mode == "upload":

            upload_antimony()

finally:
    fcntl.flock(lockf.fileno(), fcntl.LOCK_UN)
    lockf.close()

