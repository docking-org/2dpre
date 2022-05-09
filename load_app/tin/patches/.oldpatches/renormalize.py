import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

# normalizes databases to zinc ids in export files
database_export_dir = '/nfs/exb/zinc22/2d-all'
def patch_database_normalize_p1(db_port, db_path):
    all_source_f = open("{}/{}_normalize_patch_p1_source".format(BIG_SCRATCH_DIR, db_port), 'w')
    tranches = [t[0] for t in call_psql(db_port, cmd="select tranche_name from tranches", getdata=True)[1:]]
    for tranche in tranches:
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        trancheid = call_psql(db_port, cmd="select tranche_id from tranches where tranche_name='{}'".format(tranche), getdata=True)[1][0]
        exportfile = database_export_dir + "/" + tranche[0:3] + "/" + tranche + ".smi.gz"
        print(exportfile, end='\r')
        if os.path.isfile(exportfile):
            with subprocess.Popen(["zcat", exportfile], stdout=subprocess.PIPE) as zcatproc:
                with subprocess.Popen(["sed", "s/\\\\/\\\\\\\\/g"], stdin=zcatproc.stdout, stdout=subprocess.PIPE) as sedproc:
                    # the "if (NF == 2)" bit here takes care of an awkward issue where some lines get concatenated in the source file, creating extra fields and causing the patch to fail
                    with subprocess.Popen(["awk", "-v" "a={}".format(trancheid), "{if (NF == 2) print $0 \"\\t\" a}"], stdin=sedproc.stdout, stdout=subprocess.PIPE) as awkproc:
                        for line in awkproc.stdout:
                            tokens = line.decode('utf-8').strip().split()
                            smiles, zincid, trancheid = tokens[0], tokens[1], tokens[2]
                            all_source_f.write("{}\t{}\t{}\n".format(smiles, base62_rev_zincid(zincid[6:]), trancheid))

    psqlvars = {
        "source_f" : all_source_f.name
    }
    success = False
    all_source_f.close()
    code = call_psql(db_port, psqlfile=BINDIR + "/psql/renormalize_patch/tin_normalize_zincids.pgsql", vars=psqlvars)
    if code == 0:
        set_patched(db_port, "normalize_p1", True)
        success = True
    os.remove(all_source_f.name)
    return success

database_source_dirs_prepatch = ["/nfs/exb/zinc22/2dpre_results/","/nfs/exb/zinc22/2dpre_results/mx","/nfs/exb/zinc22/2dpre_results/mu","/nfs/exb/zinc22/2dpre_results/m","/nfs/exb/zinc22/2dpre_results/s","/nfs/exb/zinc22/2dpre_results/ma","/nfs/exb/zinc22/2dpre_results/sx","/nfs/exb/zinc22/2dpre_results/su","/nfs/exb/zinc22/2dpre_results/wuxi","/nfs/exb/zinc22/2dpre_results/sc","/nfs/exb/zinc22/2dpre_results/my","/nfs/exb/zinc22/2dpre_results/mc","/nfs/exb/zinc22/2dpre_results/mcule","/nfs/exb/zinc22/2dpre_results/sy"]

# normalizes databases to mappings & entries in source files
def patch_database_normalize_p2(db_port, db_path):
    all_source_f = open("{}/{}_normalize_patch_p2_source".format(BIG_SCRATCH_DIR, db_port), 'w')
    tranches = [t for t in call_psql(db_port, cmd="select tranche_name, tranche_id from tranches", getdata=True)[1:]]
    srcdirs = [(srcdir, get_or_set_catid(db_port, os.path.basename(srcdir))) for srcdir in database_source_dirs_prepatch]
    for trancheentry in tranches:
        tranche = trancheentry[0]
        trancheid = trancheentry[1]
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        print(tranche, end='\r')
        #trancheid = call_psql(db_port, cmd="select tranche_id from tranches where tranche_name='{}'".format(tranche), getdata=True)[1][0]
        for srcdir_entry in srcdirs:
            srcdir = srcdir_entry[0]
            cat_id = srcdir_entry[1]
            if os.path.isfile(srcdir + "/" + tranche):
                with subprocess.Popen(["awk", "-v", "a={}".format(trancheid), "-v", "b={}".format(cat_id), "{if (NF == 2) print $0 \"\\t\" a \"\\t\" b}", srcdir + "/" + tranche], stdout=subprocess.PIPE) as awkproc:
                    subprocess.call(["sed", "s/\\\\/\\\\\\\\/g"], stdin=awkproc.stdout, stdout=all_source_f) # look at all those backslashes!

    psqlvars = {
        "source_f" : all_source_f.name
    }
    success = False
    all_source_f.close()
    code = call_psql(db_port, psqlfile=BINDIR + "/psql/renormalize_patch/tin_normalize_everything.pgsql", vars=psqlvars)
    if code == 0:
        success = True
        set_patched(db_port, "normalize_p2", True)
    #os.remove(all_source_f.name)
    return success
