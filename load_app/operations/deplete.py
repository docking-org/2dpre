import sys, os
import subprocess
import tarfile
import shutil

from load_app.common import *

def deplete(database_port, boolval, src):

    boolval = True if sys.argv[3].lower() == "true" else False
    src = sys.argv[4]

    dtype, dval = src.split("=")

    if dtype == "catalog":
        data_catid = call_psql(database_port, cmd="select cat_id from catalog where short_name = '{}'".format(dval), getdata=True)
        cat_id = int(data_catid[1][0])

        psqlvars= {
            "cat_id" : cat_id,
            "depleted_bool" : boolval
        }

        code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_deplete_catalog.pgsql", vars=psqlvars)
        if code == 0:
            print("operation completed successfully!")
        pass

    elif dtype == "file":
        if not dval.endswith(".pre"):
            print("expects a .pre file! try again")
            sys.exit(1)

        psqlvars = {
            "source_f" : None,
            "depleted_bool" : boolval
        }

        psqlvars["source_f"] = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_deplete.txt"

        deplete_src = open(psqlvars["source_f"], 'w')

        with tarfile.open(dval, mode='r:*') as pre_source:
            for member in pre_source:
                with pre_source.extractfile(member) as f:
                    for line in f:
                        tokens = line.decode('utf-8').strip().split()
                        deplete_src.write(tokens[1] + "\n")
        
        deplete_src.close()

        code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_deplete_sample.pgsql", vars=psqlvars)
        if code == 0:
            print("operation completed successfully!")
        os.remove(psqlvars["source_f"])