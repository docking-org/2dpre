import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

def patch_database_postgres(db_port, db_path):
    print(db_port, db_path)
    sub_id_annotated = open(db_path + "/sub_id_tranche_id", 'w')
    cc_id_annotated = open(db_path + "/cc_id_tranche_id", 'w')
    cs_id_annotated = open(db_path + "/cs_id_tranche_id", 'w')
    tranche_info = open(db_path + "/tranche_info", 'w')
    tranche_id = 1

    for tranche in sorted(os.listdir(db_path + "/src")):
        print(tranche)
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        srcpath = db_path + "/src/" + tranche
        tranche_info.write("{} {}\n".format(tranche, tranche_id))

        p1 = subprocess.Popen(["awk", "-v", "a={}".format(tranche_id), "{print $3 \" \" a}", srcpath + "/substance.txt"], stdout=sub_id_annotated)
        p2 = subprocess.Popen(["awk", "-v", "a={}".format(tranche_id), "{print $2 \" \" a}", srcpath + "/supplier.txt" ], stdout=cc_id_annotated)
        p3 = subprocess.Popen(["awk", "-v", "a={}".format(tranche_id), "{print $3 \" \" a}", srcpath + "/catalog.txt"  ], stdout=cs_id_annotated)
        p1.wait()
        p2.wait()
        p3.wait()

        tranche_id += 1

    tranche_info.close()
    sub_id_annotated.close()
    cc_id_annotated.close()
    cs_id_annotated.close()
    sub_tot = sup_tot = cat_tot = 0
    with open(db_path + "/src/.len_substance") as sub_tot_f:
        sub_tot = int(sub_tot_f.read())
    with open(db_path + "/src/.len_supplier") as sup_tot_f:
        sup_tot = int(sup_tot_f.read())
    with open(db_path + "/src/.len_catalog") as cat_tot_f:
        cat_tot = int(cat_tot_f.read())

    psqlvars = {
        "tranche_sub_id_f" : sub_id_annotated.name,
        "tranche_cc_id_f" : cc_id_annotated.name,
        "tranche_cs_id_f" : cs_id_annotated.name,
        "tranche_info_f" : tranche_info.name,
        "sub_tot" : sub_tot,
        "sup_tot" : sup_tot,
        "cat_tot" : cat_tot
    }
    print(psqlvars)

    success = False

    code = call_psql(db_port, psqlfile=BINDIR + "/psql/tin_postgres_patch.pgsql", vars=psqlvars)
    if code == 0:
        set_patched(db_port, "postgres", True)
        set_patched(db_port, "substanceopt", True)
        success = True
        #with open(db_path + "/.patchedpostgres", 'w') as patchmarker:
        #    patchmarker.write("patched!")
    os.remove(db_path + "/sub_id_tranche_id")
    os.remove(db_path + "/cc_id_tranche_id")
    os.remove(db_path + "/cs_id_tranche_id")
    return success
