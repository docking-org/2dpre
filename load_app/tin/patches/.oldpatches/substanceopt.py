import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

def patch_database_substanceopt(database_port):

    code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_substance_opt_patch.pgsql")
    success = False
    if code == 0:
        set_patched(database_port, "substanceopt", True)
        success = True
    return success
