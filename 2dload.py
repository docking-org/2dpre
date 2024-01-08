import argparse, logging
import sys, os
import subprocess
import tarfile
import shutil
import datetime

from load_app.tin.operations.upload import emulate_upload as tin_upload
from load_app.tin.operations.upload_zincid import upload_zincid as tin_upload_zincid
from load_app.tin.operations.export_antimony import export_all_from_tin as tin_antimony_export
from load_app.tin.operations.export_vendors import export_vendors as tin_export_vendors
from load_app.tin.operations.export_substances import export_substances as tin_export_substances
from load_app.tin.operations.blast_dups import blast_dups_substance as tin_blast_dups_substance
from load_app.tin.operations.groupnorm import groupnorm_new as tin_groupnorm
from load_app.tin.operations.diff3d import diff3d as tin_diff3d
from load_app.tin.operations.update_depleted import undeplete_codes as tin_update_depleted
from load_app.tin.operations.delete_supplier_codes import delete_supplier_codes as tin_delete_supplier_codes


from load_app.antimony.operations.upload import emulate_upload as antimony_upload

from load_app.tin.patches.partition import TinPartitionPatch
from load_app.tin.patches.catid import CatIdPartitionPatch
from load_app.tin.patches.zincid import ZincIdPartitionPatch
from load_app.tin.patches.export import ExportPatch
from load_app.tin.patches.wackymols import WackyMolsPatch
from load_app.tin.patches.june3_2022 import June32022Patch

from load_app.antimony.patches.partition import AntimonyPartitionPatch

from load_app.common.patch import PatchPatch, UploadPatch
from load_app.common.database import Database
from load_app.common.upload import upload_complete

from load_app.tin.upload_hist import check_upload_history as tin_check_upload_history
from load_app.tin.upload_hist import validate_history as tin_validate_history

import fcntl

import argparse

def checkpatch(patchcls):
    patchobj = patchcls()
    if patchobj.is_patched():
        return
    else:
        logging.log("patching: {}".format(patchcls.__name__))
        patchobj.apply()
        print("done patching: {}".format(patchcls.__name__))

def checktinpatches(args):
    # hard-code this here because im lazy
    patchlist = [PatchPatch, UploadPatch]
    #, TinPartitionPatch, ZincIdPartitionPatch, CatIdPartitionPatch, ExportPatch, WackyMolsPatch, June32022Patch
    allpatched=True
    # for patchcls in reversed(patchlist): # go in reverse so we can abort early if we find everything is in order
    #     patch = patchcls()
    #     if patch.is_patched():
    #         break
    #     allpatched=False
    #     logging.warning('patch not applied: {}'.format(patchcls.__name__))

    # if args.op_type == 'patch' and allpatched:
    #         raise Exception('database is all patched! wont submit patch job')

    # for patchcls in patchlist: # perform patches in correct order
    #     if not args.validate:
    #         logging.info('patching: {}'.format(patchcls.__name__))
    #         patch = patchcls()
    #         patch.apply()
    #         logging.info('done patching: {}'.format(patchcls.__name__))

def checktinuptodate(args):
    nohistory = getattr(args, 'nohistory', False)
    generate_source = getattr(args, 'generate_source', False)
    if nohistory or generate_source:
        return
    transaction_id = getattr(args, 'transaction_id', None)
    if transaction_id == '___': # this is a patch
        return
    show_missing = getattr(args, 'show_missing', False)
    op_type = getattr(args, 'op_type', 'NOP')
    if   args.transaction_type == "read":
            tin_validate_history(transaction_id, show_missing=show_missing)
            assert upload_complete(transaction_id) ,'transaction {} not complete, won\'t {}'.format(transaction_id, args.op_type)
    elif args.transaction_type == "write":
            tin_validate_history(transaction_id, show_missing=show_missing)
            assert (not upload_complete(transaction_id)), 'transaction {} complete, won\'t {}'.format(transaction_id, args.op_type)

def checksbpatches(args):
    patchlist = [PatchPatch, UploadPatch, AntimonyPartitionPatch]
    allpatched=True
    for patchcls in reversed(patchlist): # go in reverse so we can abort early if we find everything is in order
        patch = patchcls()
        if patch.is_patched():
            break
        allpatched=False
        logging.warning('patch not applied: {}'.format(patchcls.__name__))

    if args.op_type == 'patch' and allpatched:
            raise Exception('database is all patched! wont submit patch job')

    for patchcls in patchlist: # perform patches in correct order
        if not args.validate:
            logging.info('patching: {}'.format(patchcls.__name__))
            patch = patchcls()
            patch.apply()
            logging.info('done patching: {}'.format(patchcls.__name__))
    #checkpatch(PatchPatch)
    #checkpatch(UploadPatch)
    #checkpatch(AntimonyPartitionPatch)
def checksbuptodate(args):
    pass

def tin_export(args):
    if args.export_type == "substance":
        tin_export_substances(args.export_dest)
    elif args.export_type == "vendors":
        tin_export_vendors(args.export_dest)
    elif args.export_type == "antimony":
        tin_antimony_export(args.export_id)

def init_logging(args):
    if getattr(args, 'verbose', False):
        logging.basicConfig(level=logging.DEBUG)
    elif getattr(args, 'quiet', False):
        logging.basicConfig(level=logging.ERROR)
    else:
        logging.basicConfig(level=logging.INFO)

# this function is basically a comment
# difficult to think of a succinct name for something weird like creating a function that returns a lambda that strings multiple functions together
# just so I'm not writing a thesaurus on each line I use it I will alias it to "wrpfnc"
def wrap_functions_for_sequential_execution(*f):
    return lambda yargs : [e(yargs) for e in f[:]]

def create_2dload_parser(just_validate=False):
    def wrpfnc(init, primary=None):
        if not just_validate and primary:
            return wrap_functions_for_sequential_execution(*(init+(primary,)))
        else:
            return wrap_functions_for_sequential_execution(*init)
    def nullfunc(args):
        pass
    parser_main = argparse.ArgumentParser()
    parser_main.add_argument("--port", type=int, help="database port to connect @")
    # we want the host's "short" name, so remove the .cluster.bkslab etc..
    thishost = os.uname()[1].split(".")[0]
    parser_main.add_argument("--host", type=str, help="machine hostname", default=thishost)
    parser_main.add_argument("--verbose", action='store_true', help='more detailed log messages')
    parser_main.add_argument("--quiet", action='store_true', help='less talking, more doing')
    parser_main.set_defaults(op_type='NOP', transaction_id='___', subsystem='___', transaction_type='read', validate=just_validate)
    #parser_main.set_defaults(func=lambda args: None)

    system_subparser = parser_main.add_subparsers(title="subsystem", help="choose a subsystem")

    parser_tin = system_subparser.add_parser("tin", help="tin subsystem, see 2dload.py [port] tin --help", aliases=["sn"])
    parser_tin.set_defaults(subsystem="tin", user="tinuser")
    parser_tin.add_argument("--no-check-history", action='store_true', dest='nohistory')
    parser_tin.add_argument('--debug', action='store_true')

    if just_validate:
        parser_main.set_defaults(validate=True)

    z22_common_init = (init_logging,)
    tin_common_init = z22_common_init + (checktinpatches, checktinuptodate)
    ant_common_init = z22_common_init + (checksbpatches, checksbuptodate)

    tin_ops_subparser = parser_tin.add_subparsers(title="operation", help="choose an operation")
    tin_patch_parser = tin_ops_subparser.add_parser("patch", help="just patch database")
    tin_patch_parser.set_defaults(func=wrpfnc(tin_common_init), op_type='patch')

    catalog_type = lambda c: '.'.join(c.split(','))
    tin_upload_parser = tin_ops_subparser.add_parser("upload", help="upload pre-processed vendor data to database")
    tin_upload_parser.add_argument("--source-dirs", required=True, help="directory(s) where tranche split & preprocessed files are stored- separated by commas")
    tin_upload_parser.add_argument("--catalogs", required=True, type=catalog_type, dest='transaction_id', help="name(s) of catalogs being uploaded, each corresponding to a source directory at the same position within the argument list- separated by commas")
    tin_upload_parser.add_argument("--diff-destination", required=True, help="where to export the database diff from this upload to")
    tin_upload_parser.add_argument("--super-id", type=int, required=False, default=0, help="optional super catalog id for depletion of related catalogs")
    tin_upload_parser.add_argument("--fake-upload", action='store_true', default=False, help="pretend to uplaod- just increment version")
    tin_upload_parser.set_defaults(func=wrpfnc(tin_common_init, tin_upload), op_type='upload', transaction_type='write', just_update_info=False)

    

    tin_update_substance_info_parser = tin_ops_subparser.add_parser("update_substance_info", help="update ancillary info on database using pre-processed vendor data")
    tin_update_substance_info_parser.add_argument("--source-dirs", nargs="+", required=True, help="directory(s) where tranche split & preprocessed files are stored")
    tin_update_substance_info_parser.add_argument("--catalogs", nargs="+", required=True, type=catalog_type, dest='transaction_id', help="name(s) of catalogs being uploaded, each corresponding to a source directory at the same position within the argument list")
    tin_update_substance_info_parser.add_argument("--diff-destination", required=True, help="where to export the database diff from this upload to")
    tin_update_substance_info_parser.add_argument("--fake-upload", action='store_true', default=False, help="pretend to uplaod- just increment version")
    tin_update_substance_info_parser.set_defaults(func=wrpfnc(tin_common_init, tin_upload), op_type='upload', transaction_type='write', just_update_info=True)

    tin_update_depleted_parser = tin_ops_subparser.add_parser("update_depleted", help="deplete or un-deplete specified supplier codes")
    tin_update_depleted_parser.add_argument("--source-dirs", nargs="+", required=True, help="directory(s) where tranche split & preprocessed files are stored")
    tin_update_depleted_parser.add_argument("--catalogs", nargs="+", required=True, type=catalog_type, dest='transaction_id', help="name(s) of catalogs being uploaded, each corresponding to a source directory at the same position within the argument list")
    tin_update_depleted_parser.add_argument("--diff-destination", required=True, help="where to export the database diff from this upload to")
    tin_update_depleted_parser.add_argument("--fake-upload", action='store_true', default=False, help="pretend to uplaod- just increment version")
    tin_update_depleted_parser.set_defaults(func=wrpfnc(tin_common_init, tin_update_depleted), op_type='update_depleted', transaction_type='write')
	
    
    tin_delete_supplier_codes_parser = tin_ops_subparser.add_parser("delete_supplier_code", help="delete all catalog substances, catalog items, catalogs from tin databases")
    tin_delete_supplier_codes_parser.add_argument("--diff-destination", required=True, help="where to export the database diff from this upload to. a copy of all cat substances/items deleted") 
    tin_delete_supplier_codes_parser.set_defaults(func=wrpfnc(tin_common_init, tin_delete_supplier_codes), op_type='delete_supplier_code', transaction_type='write', just_update_info=True)

    tin_upload_zincid_parser = tin_ops_subparser.add_parser("upload_zincid", help="upload existing zinc id annotated molecules to database, replacing existing ones or adding aliases where appropriate")
    tin_upload_zincid_parser.add_argument("--source-dirs", required=True, nargs="+", help="directory(s) where zinc id & tranche split annotated files are stored")
    tin_upload_zincid_parser.add_argument("--transaction-id", required=True, help="name of transaction for record keeping and synchronization with other databases")
    tin_upload_zincid_parser.add_argument("--diff-destination", required=True, help="where to export the database diff from this upload to")
    tin_upload_zincid_parser.add_argument("--fake-upload", action='store_true', default=False, help="pretend to upload- just increment version")
    tin_upload_zincid_parser.add_argument("--generate-source", action='store_true', default=False)
    tin_upload_zincid_parser.set_defaults(func=wrpfnc(tin_common_init, tin_upload_zincid), op_type='upload_zincid', transaction_type='write')

    tin_export_parser = tin_ops_subparser.add_parser("export", help="export database to disk")
    tin_export_parser.add_argument("export_type", choices=["substance", "vendors", "antimony"], help="choose to export substance+zincids (substance), substance+codes+zincids (vendors), or codes+codeids (antimony))")
    tin_export_parser.add_argument("export_dest", default=None, help="where exported files should be sent (hardcoded for antimony)")
    tin_export_parser.add_argument("--min-transaction", dest='transaction_id')
    tin_export_parser.add_argument("export_id", default=datetime.datetime.date(datetime.datetime.now()).isoformat(), nargs='?', help="unique identifier for this export")
    tin_export_parser.set_defaults(func=wrpfnc(tin_common_init, tin_export), user="tinuser", op_type='export')

    tin_blast_dups_parser = tin_ops_subparser.add_parser("blast", help="blast accidental duplicates out of database tables. shouldn't need to be used very often...")
    tin_blast_dups_parser.add_argument("target", choices=["substance"], help="table to target for blasting")
    tin_blast_dups_parser.add_argument("--diff-destination", required=True)
    tin_blast_dups_parser.add_argument("--min-transaction", required=True, dest='transaction_id', help="minimum transaction history identifier to target- databases with this transaction and any later ones will be 'blasted'")
    tin_blast_dups_parser.set_defaults(func=wrpfnc(tin_common_init, tin_blast_dups_substance), user="tinuser", op_type="blast") # even though this writes, we count it as a read. will fix this later, formalize all operations into the history file

    tin_groupnorm_parser = tin_ops_subparser.add_parser("groupnorm", help="normalize supplier code <> smiles groups in database")
    tin_groupnorm_parser.add_argument("--transaction-id", required=True)
    tin_groupnorm_parser.set_defaults(func=wrpfnc(tin_common_init, tin_groupnorm), op_type="groupnorm", transaction_type="write")

    tin_diff3d_parser = tin_ops_subparser.add_parser("diff3d", help="get all molecules that haven't been built in 3d & update zinc id -> tarball mappings")
    tin_diff3d_parser.add_argument("--source-dirs", required=True)
    tin_diff3d_parser.add_argument("--transaction-id", required=True)
    tin_diff3d_parser.add_argument("--tarball-ids", required=True)
    tin_diff3d_parser.add_argument("--diff-destination", required=True)
    tin_diff3d_parser.set_defaults(func=wrpfnc(tin_common_init, tin_diff3d), op_type="diff3d", transaction_type="write")

    tin_histchk_parser = tin_ops_subparser.add_parser("check", help="validate database history & patches")
    tin_histchk_parser.add_argument("--transaction-id", help="validate up to transaction in history, by default validate up to latest transaction")
    tin_histchk_parser.add_argument("--show-missing", help="show all missing required & optional transactions")
    tin_histchk_parser.set_defaults(func=wrpfnc(tin_common_init), user="tinuser")

    parser_sb = system_subparser.add_parser("antimony", help="antimony subsystem, see 2dload.py [port] antimony --help", aliases=["sb"])
    parser_sb.set_defaults(subsystem="antimony")

    sb_ops_subparser = parser_sb.add_subparsers(title="operation", help="choose an operation")

    sb_upload_parser = sb_ops_subparser.add_parser("upload", help="upload exported supplier code data to antimony")
    sb_upload_parser.add_argument("transaction_id", help="unique name for this transaction. apply this name to all databasese you are uploading to in the same time frame")
    sb_upload_parser.add_argument("diff_destination", help="where to put database diff")
    sb_upload_parser.set_defaults(func=wrpfnc(ant_common_init, antimony_upload), op_type='upload')

    sb_check_parser = sb_ops_subparser.add_parser("check")
    sb_check_parser.set_defaults(func=wrpfnc(ant_common_init,))

    sb_patch_parser = sb_ops_subparser.add_parser("patch")
    sb_patch_parser.set_defaults(func=wrpfnc(ant_common_init,), op_type='patch')

    return parser_main

if __name__ == "__main__":
    parser_main = create_2dload_parser()
    pargs = parser_main.parse_args()
    
    if pargs.verbose:
        print(pargs) # logging doesn't get initalized until pargs.func() call, so manually log it here
    Database.set_instance(pargs.host, pargs.port, pargs.subsystem + 'user', pargs.subsystem)

    lockf_location = "/tmp/zinc22_pg_{}.lock".format(pargs.port)
    if not os.path.exists(lockf_location):
        os.system("touch {}".format(lockf_location))
    lockf = open(lockf_location, 'r')

    try:
        fcntl.flock(lockf.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    except:
        logging.error("Process already using database!")
        lockf.close()
        sys.exit(1)

    try:
        pargs.func(pargs)
    finally:
        fcntl.flock(lockf.fileno(), fcntl.LOCK_UN)
        lockf.close()

    sys.exit(0)

# legacy code below
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
"""
