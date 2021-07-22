import argparse
import sys, os
import subprocess
import tarfile

BINDIR = os.path.dirname(sys.argv[0]) or '.'


def call_psql(db_port, cmd=None, psqlfile=None, vars={}, getdata=False, rethandle=False):
    psql = ["psql", "-p", str(db_port), "-d", "tin", "-U", "tinuser", "--csv"]
    
    for vname, vval in zip(vars.keys(), vars.values()):
        psql += ["--set={}={}".format(vname, vval)]
        
    if psqlfile:
        psql += ["-f", psqlfile]
    else:
        psql += ["-c", cmd]

    if getdata:
        data = []
        code = 0
        psql_p = subprocess.Popen(psql, stdout=subprocess.PIPE)
        for line in psql_p.stdout:
            line = line.decode('utf-8')
            data += [line.strip().split(",")]
            print(line.strip())
            if "ROLLBACK" in line:
                code = 1
        ecode = psql_p.wait()
        if code == 0 and not ecode == code:
            code = ecode
        return data
    elif rethandle:
        return subprocess.Popen(psql, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    else:
        code = 0
        p = subprocess.Popen(psql, stdout=subprocess.PIPE)
        for line in p.stdout:
            line = line.decode('utf-8')
            print(line.strip())
            if "ROLLBACK" in line:
                code = 1
        ecode = p.wait()
        if code == 0 and not ecode == code:
            code = ecode
        return code

def check_patched(db_port, patchtype):
    srcdir = "/local2/load"
    for partition in os.listdir(srcdir):
        ppath = "/".join([srcdir, partition])
        if os.path.isfile(ppath + "/.port"):
            with open(ppath + "/.port") as portf:
                try:
                    thisport = int(portf.read())
                    if thisport == db_port and os.path.isfile(ppath + "/.patched" + patchtype):
                        return True, ppath
                    elif thisport == db_port:
                        return False, ppath
                except:
                    continue

    print("assuming this database has already been patched, associated files cannot be found")
    return True, None

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

    code = call_psql(db_port, psqlfile=BINDIR + "/psql/tin_postgres_patch.pgsql", vars=psqlvars)
    if code == 0:
        with open(db_path + "/.patchedpostgres", 'w') as patchmarker:
            patchmarker.write("patched!")
    os.remove(db_path + "/sub_id_tranche_id")
    os.remove(db_path + "/cc_id_tranche_id")
    os.remove(db_path + "/cs_id_tranche_id")

database_source_dirs_prepatch = ['/nfs/exb/zinc22/2dpre_results/mx', '/nfs/exb/zinc22/2dpre_results/mu', '/nfs/exb/zinc22/2dpre_results/m', '/nfs/exb/zinc22/2dpre_results/s', '/nfs/exb/zinc22/2dpre_results/ma', '/nfs/exb/zinc22/2dpre_results/sx', '/nfs/exb/zinc22/2dpre_results/su', '/nfs/exb/zinc22/2dpre_results/wuxi', '/nfs/exb/zinc22/2dpre_results/sc', '/nfs/exb/zinc22/2dpre_results/my', '/nfs/exb/zinc22/2dpre_results/mc', '/nfs/exb/zinc22/2dpre_results/mcule', '/nfs/exb/zinc22/2dpre_results/sy', '/nfs/exb/zinc22/2dpre_results/zinc20-stock']
def patch_database_catsub(db_port, db_path):
    all_source_f = open(db_path + "/catsub_patch_source", 'w')
    trancheid = 1
    for tranche in sorted(os.listdir(db_path + "/src")):
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        print(tranche)
        for srcdir in database_source_dirs_prepatch:
            if os.path.isfile(srcdir + "/" + tranche):
                subprocess.call(["awk", "-v", "a={}".format(trancheid), "{print $0 \"\\t\" a}", srcdir + "/" + tranche], stdout=all_source_f)
        trancheid += 1
    psqlvars = {
        "source_f" : db_path + "/catsub_patch_source"
    }
    all_source_f.close()
    code = call_psql(db_port, psqlfile=BINDIR + "/psql/tin_catsub_patch_rev.pgsql", vars=psqlvars)
    if code == 0:
        with open(db_path + "/.patchedcatsub2", 'w') as patchmarker:
            patchmarker.write("patched!")
    os.remove(db_path + "/catsub_patch_source")

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
    sys.exit(0)

try:
    database_port = int(sys.argv[1])
except:
    print("port must be an integer!")
    sys.exit(1)

print(database_port)
patched, dbpath = check_patched(database_port, "postgres")
if not patched:
    print("this database hasn't received the postgres patch, patching now")
    patch_database_postgres(database_port, dbpath)

patched, dbpath = check_patched(database_port, "catsub2")
if not patched:
    print("this database hasn't received the catsub 2 patch, patching now")
    patch_database_catsub(database_port, dbpath)

chosen_mode = "none" if len(sys.argv) < 3 else sys.argv[2]

if chosen_mode == "upload":

    source_f = sys.argv[3]
    cat_shortname = sys.argv[4]

    if not os.path.isfile(source_f):
        print("file to upload does not exist!")
        sys.exit(1)
    elif not source_f.endswith(".pre"):
        print("expects a .pre file!")
        sys.exit(1)

    psqlvars = {
        "source_f" : None,
        "sb_count" : 0,
        "cc_count" : 0,
        "cs_count" : 0
    }

    psqlvars["source_f"] = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_" + cat_shortname + "_upload.txt"
    psqlvars["sb_count"] = int(call_psql(database_port, cmd="select nextval('sub_id_seq')", getdata=True)[1][0])
    psqlvars["cc_count"] = int(call_psql(database_port, cmd="select nextval('cat_content_id_seq')", getdata=True)[1][0])
    psqlvars["cs_count"] = int(call_psql(database_port, cmd="select nextval('cat_sub_itm_id_seq')", getdata=True)[1][0])

    print(psqlvars)

    psql_source_f = open(psqlvars["source_f"], 'w')

    data_catid = call_psql(database_port, cmd="select cat_id from catalog where short_name = '{}'".format(cat_shortname), getdata=True)
    if len(data_catid) <= 1:
        data_catid = call_psql(database_port, cmd="insert into catalog(name, short_name, updated) values ('{}', '{}', 'now()') returning cat_id".format(cat_shortname, cat_shortname), getdata=True)
    cat_id = int(data_catid[1][0])

    print("processing file for postgres...")
    with tarfile.open(source_f, mode='r:*') as pre_source:
        for member in pre_source:
            print("processing", member)
            tranchename = member.name
            tranche_id = int(call_psql(database_port, cmd="select tranche_id from tranches where tranche_name = '{}'".format(tranchename), getdata=True)[1][0])

            f = pre_source.extractfile(member)
            for line in f:
                line = line.decode('utf-8')
                psql_source_f.write(' '.join(line.strip().split() + [str(cat_id), str(tranche_id)]) + "\n")

    psql_source_f.close()
    #sys.exit(1)
    code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_revised_copy.pgsql", vars=psqlvars)
    if code == 0:
        print("operation completed successfully!")
    os.remove(psqlvars["source_f"])

if chosen_mode == "deplete":
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
        pass


    

    
