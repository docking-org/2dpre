import argparse
import sys, os
import subprocess
import tarfile
import shutil

BINDIR = os.path.dirname(sys.argv[0]) or '.'
BIG_SCRATCH_DIR = "/local2/load"

# handy function for calling tin postgres commands or files
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

def get_db_path(db_port):
    srcdir = "/local2/load"
    db_path = None
    for partition in os.listdir(srcdir):
        if not len(partition) == 15 or not partition[0] == "H":
            continue
        ppath = "/".join([srcdir, partition])
        if os.path.isfile(ppath + "/.port"):
            with open(ppath + "/.port") as portf:
                thisport = int(portf.read())
                if thisport == db_port:
                    if db_path:
                        print("multiple databases are hosted on this port!")
                        print(db_path, ppath, "are both on port {}".format(db_port))
                        sys.exit(1)
                    db_path = ppath
    return db_path

existing_patches = ["postgres", "catsub2", "escape", "substanceopt"]
def patch_patch(db_port, db_path):
    patch_table_exists = call_psql(db_port, cmd="\\d patches")
    if patch_table_exists == 0:
        return
    print("creating patches table since it does not exist yet!")
    call_psql(db_port, cmd="create table patches(patchname varchar, patched boolean)")
    if not db_path:
        print("could not find associated legacy files, assuming everything has been patched")
        for patch in existing_patches:
            call_psql(db_port, cmd="insert into patches(patchname, patched) values ('{}', {})".format(patch, "true"))
    else:
        already_patched = [p[8:] for p in filter(lambda x:x.startswith(".patched"), os.listdir(db_path))]
        for patch in already_patched:
            call_psql(db_port, cmd="insert into patches(patchname, patched) values ('{}', {})".format(patch, "true"))

def get_patched(db_port, patch_name):
    patched_value = call_psql(db_port, cmd="select patched from patches where patchname = '{}'".format(patch_name), getdata=True)
    if len(patched_value) <= 1:
        return False
    else:
        if patched_value[1][0] == "f":
            return False
        else:
            return True

def set_patched(db_port, patch_name, patched):
    patch_name_exists = call_psql(db_port, cmd="select * from patches where patchname = '{}'".format(patch_name), getdata=True)
    if len(patch_name_exists) <= 1:
        call_psql(db_port, cmd="insert into patches(patchname, patched) values ('{}', {})".format(patch_name, "true" if patched else "false"))
    else:
        call_psql(db_port, cmd="update patches set patched = {} where patchname = '{}'".format("true" if patched else "false", patch_name))

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

database_source_dirs_prepatch = ['/nfs/exb/zinc22/2dpre_results/mx', '/nfs/exb/zinc22/2dpre_results/mu', '/nfs/exb/zinc22/2dpre_results/m', '/nfs/exb/zinc22/2dpre_results/s', '/nfs/exb/zinc22/2dpre_results/ma', '/nfs/exb/zinc22/2dpre_results/sx', '/nfs/exb/zinc22/2dpre_results/su', '/nfs/exb/zinc22/2dpre_results/wuxi', '/nfs/exb/zinc22/2dpre_results/sc', '/nfs/exb/zinc22/2dpre_results/my', '/nfs/exb/zinc22/2dpre_results/mc', '/nfs/exb/zinc22/2dpre_results/mcule', '/nfs/exb/zinc22/2dpre_results/sy']
# soon to be phased out- normalize_p2 is essentially the catsub patch but better
def patch_database_catsub(db_port, db_path):
    all_source_f = None
    if not db_path:
        all_source_f = open("{}/{}_catsub_patch_source".format(BIG_SCRATCH_DIR, db_port), 'w')
    else:
        all_source_f = open(db_path + "/catsub_patch_source", 'w')
    #trancheid = 1
    for tranche in sorted(os.listdir(db_path + "/src")):
        if not (tranche[0] == 'H' and (tranche[3] == "P" or tranche[3] == "M")):
            continue
        print(tranche)
        trancheid = call_psql(db_port, cmd="select tranche_id from tranches where tranche_name='{}'".format(tranche), getdata=True)[1][0]
        for srcdir in database_source_dirs_prepatch:
            if os.path.isfile(srcdir + "/" + tranche):
                #subprocess.call(["awk", "-v", "a={}".format(trancheid), "{print $0 \"\\t\" a}", srcdir + "/" + tranche], stdout=all_source_f)
                with subprocess.Popen(["awk", "-v", "a={}".format(trancheid), "{print $0 \"\\t\" a}", srcdir + "/" + tranche], stdout=subprocess.PIPE) as awkproc:
                    subprocess.call(["sed", "s/\\\\/\\\\\\\\/g"], stdin=awkproc.stdout, stdout=all_source_f) # look at all those backslashes!

        #trancheid += 1
    psqlvars = {
        "source_f" : all_source_f.name
    }
    all_source_f.close()
    code = call_psql(db_port, psqlfile=BINDIR + "/psql/tin_catsub_patch_rev.pgsql", vars=psqlvars)
    if code == 0:
        set_patched(db_port, "catsub2", True)
        #with open(db_path + "/.patchedcatsub2", 'w') as patchmarker:
            #patchmarker.write("patched!")
    os.remove(db_path + "/catsub_patch_source")

digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
digits_map = {d:i for i, d in enumerate(digits)}
def base62_rev_zincid(n):
    tot = 0
    # manually unrolling this loop to optimize for decoding zinc ids
    tot += digits_map[n[9]]
    tot += digits_map[n[8]] * 62
    tot += digits_map[n[7]] * 3844
    tot += digits_map[n[6]] * 238328
    tot += digits_map[n[5]] * 14776336
    tot += digits_map[n[4]] * 916132832
    tot += digits_map[n[3]] * 56800235584
    tot += digits_map[n[2]] * 3521614606208
    tot += digits_map[n[1]] * 218340105584896
    tot += digits_map[n[0]] * 13537086546263552
    #for i, d in enumerate(reversed(n)):
    #    tot += digits_map[d] * 62**i
    return tot

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
                    with subprocess.Popen(["awk", "-v" "a={}".format(trancheid), "{print $0 \"\\t\" a}"], stdin=sedproc.stdout, stdout=subprocess.PIPE) as awkproc:
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

def get_or_set_catid(port, cat_shortname):
    data_catid = call_psql(database_port, cmd="select cat_id from catalog where short_name = '{}'".format(cat_shortname), getdata=True)
    if len(data_catid) <= 1:
        data_catid = call_psql(database_port, cmd="insert into catalog(name, short_name, updated) values ('{}','{}', 'now()') returning cat_id".format(cat_shortname, cat_shortname), getdata=True)
    cat_id = int(data_catid[1][0])
    return cat_id

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
                with subprocess.Popen(["awk", "-v", "a={}".format(trancheid), "-v", "b={}".format(cat_id), "{print $0 \"\\t\" a \"\\t\" b}", srcdir + "/" + tranche], stdout=subprocess.PIPE) as awkproc:
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
    print("       ----> uploads to a database using legacy files. Involves re-doing the catsub2 patch")
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
    #sys.exit(0)
    print("this database hasn't received the postgres patch, patching now")
    if not patch_database_postgres(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

#sys.exit(0)
if not get_patched(database_port, "escape") and not nopatch:
    print("this database hasn't received the escape characters patch, patching now")
    print("this patch will involve performing the catsub2 patch again")
    if not patch_database_escape(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "substanceopt") and not nopatch:
    print("thie database hasn't received the substance optimization patch! Doing it now...")
    # this patch is pretty simple and doesn't require any prepared files, so we don't bother making a function call for it
    code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_substance_opt_patch.pgsql")
    if code == 0:
        set_patched(database_port, "substanceopt", True)

if not get_patched(database_port, "normalize_p1"):
    print("this database hasn't received part 1 of the renormalization patch! performing now")
    if not patch_database_normalize_p1(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

if not get_patched(database_port, "normalize_p2"):
    print("this database hasn't received part 2 of the renormalization patch! performing now")
    if not patch_database_normalize_p2(database_port, dbpath):
        print("patch failed!")
        sys.exit(1)

#if not get_patched(database_port, "catsub2") and not nopatch:
#    print("this database hasn't received the catsub 2 patch, patching now")
#    patch_database_catsub(database_port, dbpath)

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

    cat_id = get_or_set_catid(database_port, cat_shortname)

    print("processing file for postgres...")
    with tarfile.open(source_f, mode='r:*') as pre_source:
        for member in pre_source:
            print("processing", member)
            tranchename = member.name
            tranche_id = int(call_psql(database_port, cmd="select tranche_id from tranches where tranche_name = '{}'".format(tranchename), getdata=True)[1][0])

            f = pre_source.extractfile(member)
            for line in f:
                line = line.decode('utf-8')
                escaped_line = line.replace('\\', '\\\\').strip()
                psql_source_f.write(' '.join(escaped_line.split() + [str(cat_id), str(tranche_id)]) + "\n")

    psql_source_f.close()
    #sys.exit(1)
    #code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_revised_copy.pgsql", vars=psqlvars)
    #if code == 0:
    #    print("operation completed successfully!")
    #os.remove(psqlvars["source_f"])

# new upload tool for uploading legacy data to new system
if chosen_mode == "upload_legacy":
    partition_number = int(sys.argv[3])
    partition_label = None

    with open(BINDIR + "/utils-2d/common_files/partitions.txt") as pfile:
        for line in pfile:
            tokens = line.split()
            plabel = tokens[0] + "_" + tokens[1]
            pnum = int(tokens[2])
            if pnum == partition_number:
                partition_label = plabel
                break

    if not partition_label:
        print("partition not found!")
        sys.exit(1)

    partition_dir = "/local2/load/" + partition_label
    partition_dir_src = partition_dir + "/src"
    tranche_info_f = open(partition_dir + "/tranche_info", 'w')
    tranches = sorted(list(filter(lambda x:x.startswith("H") and len(x) == 7, os.listdir(partition_dir_src))))
    for i, tranche in enumerate(tranches):
        tranche_info_f.write(str(i+1) + " " + tranche + "\n")
    tranche_info_f.close()

    call_psql(database_port, cmd="create table if not exists tranches(tranche_id smallint, tranche_name varchar)")
    call_psql(database_port, cmd="truncate table tranches")
    call_psql(database_port, cmd="copy tranches(tranche_id, tranche_name) from '{}' delimiter ' '".format(tranche_info_f.name))
    
    error = False
    raw_upload_sub = open(partition_dir + "/legacy_upload_sub", 'w')
    raw_upload_sup = open(partition_dir + "/legacy_upload_sup", 'w')
    raw_upload_cat = open(partition_dir + "/legacy_upload_cat", 'w')

    for tranche_id, tranche in enumerate(tranches):
        print("{} : {}/{}".format(tranche, (tranche_id+1), len(tranches)))
        tranche_id += 1
        tranche_dir = partition_dir_src + "/" + tranche
        archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(tranche_dir)))

        for archive in archives:
            archive_name = '.'.join(archive.split('.')[:-2])
            archive_dir = tranche_dir + "/" + archive_name
            shortname = archive_name.split("_")[1]

            cat_id = get_or_set_catid(database_port, shortname)

            subprocess.call(["tar", "-C", tranche_dir, "-xzf", archive_dir + '.tar.gz'])
            p1 = subprocess.Popen(["gzip", "-d", "-f", archive_dir + "/sub.gz"])
            p2 = subprocess.Popen(["gzip", "-d", "-f", archive_dir + "/sup.gz"])
            p3 = subprocess.Popen(["gzip", "-d", "-f", archive_dir + "/cat.gz"])

            ecode = p1.wait()
            if ecode != 0:
                error = True
                print("operation failed- sub file unable to be extracted!")
                break
            awkstring = "{print $1 \" \" $3 \" \" " + str(tranche_id) + "}"
            with subprocess.Popen(["awk", awkstring, archive_dir + "/sub"], stdout=subprocess.PIPE) as subp:
                for line in subp.stdout:
                    raw_upload_sub.write(line.decode('utf-8').replace("\\", "\\\\"))
            ecode = p2.wait()
            if ecode != 0:
                error = True
                print("operation failed- sup file unable to be extracted!")
                break
            awkstring = "{print $1 \" \" $2 \" \" " + str(cat_id) + "}"
            with subprocess.Popen(["awk", awkstring, archive_dir + "/sup"], stdout=subprocess.PIPE) as supp:
                for line in supp.stdout:
                    raw_upload_sup.write(line.decode('utf-8'))
            ecode = p3.wait()
            if ecode != 0:
                print("couldn't extract cat file, this is okay. Continuing!")
            awkstring = "{print $1 \" \" $2 \" \" $3 \" \" " + str(tranche_id) + "}"
            with subprocess.Popen(["awk", awkstring, archive_dir + "/cat"], stdout=subprocess.PIPE) as catp:
                for line in catp.stdout:
                    raw_upload_cat.write(line.decode('utf-8'))

            shutil.rmtree(archive_dir)
        if error:
            break
            
    raw_upload_sub.close()
    raw_upload_sup.close()
    raw_upload_cat.close()

    psqlvars = {
        "raw_upload_sub" : raw_upload_sub.name,
        "raw_upload_sup" : raw_upload_sup.name,
        "raw_upload_cat" : raw_upload_cat.name
    }

    if not error:
        code = call_psql(database_port, psqlfile=BINDIR + "/psql/tin_fullcopy_legacy.pgsql", vars=psqlvars)
        if code == 0:
            print("operation completed successfully! now running catsub patch")
            set_patched(database_port, "postgres", True)
            set_patched(database_port, "escape", True)
            set_patched(database_port, "catsub2", False)
            #with open(partition_dir + "/.patchedpostgres", 'w') as patchmarker_psql:
            #    patchmarker_psql.write("patched!\n")
            patch_database_catsub(database_port, partition_dir)
        else:
            print("operation failed!")

    os.remove(raw_upload_sub.name)
    os.remove(raw_upload_sup.name)
    os.remove(raw_upload_cat.name)


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


    

    
