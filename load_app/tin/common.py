import sys, os
import subprocess
import tarfile
import shutil

BINDIR = os.path.dirname(sys.argv[0]) or '.'
BIG_SCRATCH_DIR = "/local2/load"

# handy function for calling tin postgres commands or files
def call_psql(db_port, cmd=None, psqlfile=None, vars={}, getdata=False, rethandle=False, stdin=None):
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
        psql_p = subprocess.Popen(psql, stdin=stdin, stdout=subprocess.PIPE)
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
        return subprocess.Popen(psql, stdin=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    else:
        code = 0
        p = subprocess.Popen(psql, stdin=stdin, stdout=subprocess.PIPE)
        for line in p.stdout:
            line = line.decode('utf-8')
            print(line.strip())
            if "ROLLBACK" in line:
                code = 1
        ecode = p.wait()
        if code == 0 and not ecode == code:
            code = ecode
        return code

def increment_version(db_port, uploadname):
    call_psql(db_port, cmd="update tin_meta set ivalue = ivalue + 1 where varname = 'version'")
    version_no = get_version(db_port)
    call_psql(db_port, cmd="insert into tin_meta(varname, svalue, ivalue) (values ('upload_name', '{}', {}))".format(uploadname, version_no))

def get_version(db_port):
    data = call_psql(db_port, cmd="select ivalue from tin_meta where varname = 'version'", getdata=True)[1][0]
    return int(data)

def get_tranche_id(port, tranchename):
    data = call_psql(port, cmd="select tranche_id from tranches where tranche_name = '{}'".format(tranchename), getdata=True)
    return int(data[1][0])

def upload_complete(port, transaction_id):
    data = call_psql(port, cmd="select svalue from tin_meta where svalue = '{}'".format(transaction_id), getdata=True)
    if len(data) > 1:
        return True
    else:
        return False

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

def get_or_set_catid(database_port, cat_shortname):
    data_catid = call_psql(database_port, cmd="select cat_id from catalog where short_name = '{}'".format(cat_shortname), getdata=True)
    if len(data_catid) <= 1:
        data_catid = call_psql(database_port, cmd="insert into catalog(name, short_name, updated) values ('{}','{}', 'now()') returning cat_id".format(cat_shortname, cat_shortname), getdata=True)
    cat_id = int(data_catid[1][0])
    return cat_id

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

def get_tranches(port):
    data = call_psql(port, cmd="select tranche_name from tranches", getdata=True)
    return [d[0] for d in data[1:]]

def zincid_to_subid_opt(infile, outfile, tranche_id, zincid_pos, only_output_zincid=False, writemode='w'):
    with open(outfile, writemode) as out:
        with open(infile, 'r') as src:
            # zincid column location specified beforehand
            for line in src:
                tokens = line.strip().split()
                zincid = tokens[zincid_pos-1]
                try:
                    sub_id = base62_rev_zincid(zincid[6:])
                except:
                    print(tokens)
                    raise NameError("asdf")
                if not only_output_zincid:
                    out.write(" ".join(tokens[:zincid_pos-1] + [str(sub_id), str(tranche_id)] + tokens[:zincid_pos-1] + tokens[zincid_pos:]) + "\n")
                else:
                    out.write(" ".join([str(sub_id), str(tranche_id)]) + "\n")

existing_patches = ["postgres", "catsub2", "escape", "substanceopt", "renormalize_p1", "renormalize_p2"]
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
