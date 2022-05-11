import argparse
import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *
from load_app.tin.patches.escape import *
from load_app.tin.patches.postgres import *
from load_app.tin.patches.renormalize import *
from load_app.tin.patches.substanceopt import *
from load_app.tin.patches.version import *

from load_app.tin.operations.deplete import deplete as tin_deplete
from load_app.tin.operations.upload import upload as tin_upload
from load_app.tin.operations.upload_legacy import upload_legacy as tin_upload_legacy
from load_app.tin.operations.antimony_export import export_all_from_tin as export_antimony
#from load_app.tin.apply_config import apply_config

from load_app.antimony.operations.upload import upload_antimony

if len(sys.argv) == 1:
    print("usages:")
    print("2dload.py [port] upload [source_f.pre] [catalog_shortname]")
    print("       ----> uploads source_f.pre to database @ port")
    print("       ----> example:")
    print("       ----> 2dload_new.py 5434 upload /nfs/exb/zinc22/2dpre_results/s/34.pre s")
    print()
    print("2dload.py [port]")
    print("       ----> applies pending patches to database @ port without doing anything else")
    print()
    print("2dload.py [port] deplete [true/false] {file=[file.pre] | catalog=[short_name]}")
    print("       ----> depletes a given catalog or supplier code sample")
    print("       ----> example:")
    print("       ----> 2dload_new.py 5434 deplete true file=/nfs/exb/zinc22/2dpre_results/zinc20-stock/37.pre")
    print("       ----> 2dload_new.py 5434 deplete true catalog=zinc20-stock")
    print()
    print("2dload.py [port] upload_legacy [partition number]")
    print("       ----> uploads to a database using legacy files")
    sys.exit(0)

# begin main functionality

chosen_mode = "none" if len(sys.argv) < 3 else sys.argv[2]

nopatch = False
try:
    database_port = sys.argv[1]
    if database_port.endswith('x') or chosen_mode == "upload_legacy":
        nopatch = True
        database_port = database_port[0:4]
    database_port = int(database_port)
except:
    print("port must be an integer!")
    sys.exit(1)

# keep database config up to date with any changes
# apply_config(database_port)

dbpath = get_db_path(database_port)
# make sure patches are hosted on postgres now, rather than on disk
patch_patch(database_port, dbpath)

# sort of a messy way to do patches (code-wise) but it functions
print(database_port)
if not get_patched(database_port, "postgres") and not nopatch:
    print("this database hasn't received the postgres patch, patching now")
    if not patch_database_postgres(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "escape") and not nopatch:
    print("this database hasn't received the escape characters patch, patching now")
    if not patch_database_escape(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "substanceopt") and not nopatch:
    print("thie database hasn't received the substance optimization patch! Doing it now...")
    if not patch_database_substanceopt(database_port):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "normalize_p1") and not nopatch:
    print("this database hasn't received part 1 of the renormalization patch! performing now")
    if not patch_database_normalize_p1(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "normalize_p2") and not nopatch:
    print("this database hasn't received part 2 of the renormalization patch! performing now")
    if not patch_database_normalize_p2(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "version") and not nopatch:
    print("adding versioning system to tin!")
    if not patch_database_version(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if chosen_mode == "upload":

    source_files = sys.argv[3].split()
    cat_shortnames = sys.argv[4].split()

    tin_upload(database_port, source_files, cat_shortnames)

# new upload tool for uploading legacy data to new system
if chosen_mode == "upload_legacy":

    partition_number = int(sys.argv[3])

    tin_upload_legacy(database_port, partition_number)

if chosen_mode == "deplete":

    boolval = True if sys.argv[3].lower() == "true" else False
    src = sys.argv[4]

    tin_deplete(database_port, boolval, src)

# should work on logically separating tin/antimony operations within the command line arguments
# e.g tin operations are all prefixed like:
# 2dload.py [port] tin [operation] [args]
# similarly with antimony:
# 2dload.py [port] antimony [operation] [args]
if chosen_mode == "tin_export_antimony":

    hostname = os.uname()[1].split(".")[0]

    antimony_export(hostname, database_port)

if chosen_mode == "antimony_upload":

    hostname = os.uname()[1].split(".")[0]

    upload_antimony(hostname, database_port)