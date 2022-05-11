import sys, os
import subprocess
import tarfile
import shutil

from load_app.tin.common import *

def upload_legacy(database_port, partition_number):
    
    #partition_number = int(sys.argv[3])
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
            set_patched(database_port, "normalize_p1", False)
            set_patched(database_port, "normalize_p2", False)
        else:
            print("operation failed!")

    os.remove(raw_upload_sub.name)
    os.remove(raw_upload_sup.name)
    os.remove(raw_upload_cat.name)
