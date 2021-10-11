import sys, os
import subprocess
import tarfile
import shutil

from load_app.common import *

def patch_database_escape(db_port, db_path):
    if not db_path:
        print("can't do the escape patch without legacy files to reference!")
        sys.exit(1)
    all_source_f = open("{}/{}_escape_patch_source".format(BIG_SCRATCH_DIR, db_port), 'w')
    tranches = [t[0] for t in call_psql(db_port, cmd="select tranche_name from tranches", getdata=True)[1:]]
    for tranche in tranches:
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        print(tranche)
        trancheid = call_psql(db_port, cmd="select tranche_id from tranches where tranche_name='{}'".format(tranche), getdata=True)[1][0]
        with open(db_path + "/src/" + tranche + "/substance.txt", 'r') as subf:
            for line in subf:
                line = line.replace("\\", "\\\\").strip()
                tokens = line.split()
                all_source_f.write(" ".join([tokens[0], tokens[2], str(trancheid)]) + "\n")

    all_source_f.close()

    psqlvars = {
        "source_f" : all_source_f.name
    }
    success = False
    code = call_psql(db_port, psqlfile=BINDIR + "/psql/tin_escape_patch.pgsql", vars=psqlvars)
    os.remove(all_source_f.name)
    if code == 0:
        success = True
        set_patched(db_port, "escape", True)
        set_patched(db_port, "catsub2", False)
        set_patched(db_port, "substanceopt", True)
        patch_database_catsub(db_port, db_path)
    return success