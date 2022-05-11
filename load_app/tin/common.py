import sys, os
import subprocess
import tarfile
import shutil

BINDIR = os.path.dirname(sys.argv[0]) or '.'
BIG_SCRATCH_DIR = "/local2/load"

def get_tranche_id(port, tranchename):
    data = Database.instance.select("select tranche_id from tranches where tranche_name = '{}'".format(tranchename)).first().tranche_id
    return int(data)

# deprecated
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
    data_catid = Database.instance.select("select cat_id from catalog where short_name = '{}'".format(cat_shortname))
    if data_catid.empty():
        data_catid = Database.instance.select("insert into catalog(name, short_name, updated) values ('{}','{}', 'now()') returning cat_id".format(cat_shortname, cat_shortname))
    cat_id = data_catid.first().cat_id
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
    data = Database.instance.select("select tranche_name from tranches").all()
    return [d.tranche_name for d in data]

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