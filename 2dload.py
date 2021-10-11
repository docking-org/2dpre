import argparse
import sys, os
import subprocess
import tarfile
import shutil

from load_app.common import *
from load_app.patches.escape import *
from load_app.patches.postgres import *
from load_app.patches.renormalize import *
from load_app.patches.substanceopt import *

from load_app.operations.deplete import deplete
from load_app.operations.upload import upload
from load_app.operations.upload_legacy import upload_legacy

if len(sys.argv) == 1:
    print("usages:")
    print("2dload_new.py [port] upload [source_f.pre] [catalog_shortname]")
    print("       ----> uploads source_f.pre to database @ port")
    print("       ----> example:")
    print("       ----> 2dload_new.py 5434 upload /nfs/exb/zinc22/2dpre_results/s/34.pre s")
    print()
    print("2dload_new.py [port]")
    print("       ----> applies pending patches to database @ port without doing anything else")
    print()
    print("2dload_new.py [port] deplete [true/false] {file=[file.pre] | catalog=[short_name]}")
    print("       ----> depletes a given catalog or supplier code sample")
    print("       ----> example:")
    print("       ----> 2dload_new.py 5434 deplete true file=/nfs/exb/zinc22/2dpre_results/zinc20-stock/37.pre")
    print("       ----> 2dload_new.py 5434 deplete true catalog=zinc20-stock")
    print()
    print("2dload_new.py [port] upload_legacy [partition number]")
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

dbpath = get_db_path(database_port)
# make sure patches are hosted on postgres now, rather than on disk
patch_patch(database_port, dbpath)

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

if chosen_mode == "upload":

    source_f = sys.argv[3]
    cat_shortname = sys.argv[4]

    upload(database_port, source_f, cat_shortname)

# new upload tool for uploading legacy data to new system
if chosen_mode == "upload_legacy":

    partition_number = int(sys.argv[3])

    upload_legacy(database_port, partition_number)

if chosen_mode == "deplete":

    boolval = True if sys.argv[3].lower() == "true" else False
    src = sys.argv[4]

    deplete(database_port, boolval, src)