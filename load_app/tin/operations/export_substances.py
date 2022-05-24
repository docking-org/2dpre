from load_app.common.consts import *
from load_app.common.database import Database
from load_app.tin.common import subid_to_zincid_opt
import os, sys, subprocess, shutil

def export_substances(destination):

    export_tmp_dest = BIG_SCRATCH_DIR + "/export_{}_{}".format(Database.instance.host, Database.instance.port)
    export_raw_dest = export_tmp_dest + "/raw_substances"
    export_raw_split_dest = export_tmp_dest + "/split_substances"

    if os.path.exists(export_raw_split_dest):
        shutil.rmtree(export_raw_split_dest)

    subprocess.call(["mkdir", "-p", export_raw_split_dest])
    subprocess.call(["chmod", "777", export_tmp_dest])

    psqlvars = {"output_file" : export_raw_dest}
    Database.instance.call_file(BINDIR + '/psql/tin/export_substance.pgsql', vars=psqlvars)

    subprocess.call(["awk", "-v", "t={}".format(export_raw_split_dest), '{print $1 "\t" $2>t"/"$3}', export_raw_dest])

    for tranche in os.listdir(export_raw_split_dest):
        assert(len(tranche) == 7)
        hac = tranche[:3]
        dstfile = "/".join([destination, hac, tranche]) + '.smi'
        subprocess.call(["mkdir", "-p", os.path.dirname(dstfile)])
        subid_to_zincid_opt(export_raw_split_dest + "/" + tranche, dstfile, tranche, 2)
        subprocess.call(["gzip", dstfile])

    os.remove(export_raw_dest)
    shutil.rmtree(export_raw_split_dest)
