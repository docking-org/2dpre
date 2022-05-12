import argparse
import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.operations.upload import emulate_upload as tin_upload
from load_app.tin.operations.upload_zincid import upload_zincid as tin_upload_zincid
from load_app.tin.operations.antimony_export import export_all_from_tin as export_antimony_from_tin
from load_app.antimony.operations.upload import upload_antimony

from load_app.tin.patches.partition import TinPartitionPatch
from load_app.tin.patches.catid import CatIdPartitionPatch
from load_app.tin.patches.zincid import ZincIdPartitionPatch

from load_app.common.patch import PatchPatch, UploadPatch
from load_app.common.database import Database


import fcntl

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
    fcntl.flock(lockf.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
except:
    print("Process already using database!")
    lockf.close()
    sys.exit(1)

def checkpatch(patchcls):
    patchobj = patchcls()
    if patchobj.is_patched():
        return
    else:
        print("patching: {}".format(patchcls.__name__))
        patchobj.apply()
        print("done patching: {}".format(patchcls.__name__))

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

        if chosen_mode == "upload":
            source_files = args[0].replace(',', ' ').split()
            cat_shortnames = args[1].replace(',', ' ').split()
            tin_upload(source_files, cat_shortnames)

        if chosen_mode == "upload_zincid":
            source_dirs = args[0].split(',')
            transaction_id = args[1]
            tin_upload_zincid(source_dirs, transaction_id)

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

