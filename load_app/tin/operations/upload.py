import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

def upload(database_port, source_files, cat_shortnames):

    #source_f = sys.argv[3]
    #cat_shortname = sys.argv[4]

    for source_f in source_files:
        if not os.path.isfile(source_f):
            print("file to upload does not exist!", source_f)
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

    psqlvars["source_f"] = (os.environ.get("TEMPDIR") or "/local2/load") + "/" + str(database_port) + "_upload.txt"
    psqlvars["sb_count"] = int(call_psql(database_port, cmd="select nextval('sub_id_seq')", getdata=True)[1][0])
    psqlvars["cc_count"] = int(call_psql(database_port, cmd="select nextval('cat_content_id_seq')", getdata=True)[1][0])
    psqlvars["cs_count"] = int(call_psql(database_port, cmd="select nextval('cat_sub_itm_id_seq')", getdata=True)[1][0])

    print(psqlvars)

    psql_source_f = open(psqlvars["source_f"], 'w')

    print("processing file for postgres...")
    for source_f, cat_shortname in zip(source_files, cat_shortnames):
        cat_id = get_or_set_catid(database_port, cat_shortname)
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

    code = call_psql(database_port, vars=psqlvars, psqlfile=BINDIR + "/psql/tin_revised_copy.pgsql")

    if code == 0:
        increment_version(database_port)
        print("upload successfull!")

    os.remove(psql_source_f.name)
