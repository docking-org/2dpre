import subprocess
import os, sys

#from load_app.antimony.common import antimony_src_dir, antimony_stage_dir, antimony_partition_map, num_digits, get_machine_id
# get_partition_id

num_digits = 2
BINDIR = os.path.dirname(sys.argv[0]) or '.'
BIG_SCRATCH_DIR = "/local2/load"
antimony_scratch_dir = "/local2/load"
antimony_src_dir = "/nfs/exh/zinc22/antimony/src"
antimony_stage_dir = "/nfs/exh/zinc22/antimony/stage"
antimony_partition_map = {}
antimony_machine_partition_map = {}

with open(BINDIR + "/load_app/antimony/machine_partition_map.txt") as pmapf:
    for line in pmapf:
        tokens = line.strip().split()
        antimony_machine_partition_map[tokens[0] + ":" + tokens[1]] = tokens[2]

with open(BINDIR + "/load_app/antimony/hash_partition_map.txt") as pmapf:
    for line in pmapf:
        tokens = line.strip().split()
        antimony_partition_map[tokens[0]] = tokens[1]

def get_partition_id(host, port):
    return antimony_machine_partition_map[host + ":" + str(port)]

def get_machine_id(host, port):
    psql = ["psql", "-h", "n-1-17", "-p", "5534", "-d", "zinc22_common", "-U", "zincuser", "--csv", "-c", "select machine_id from tin_machines where hostname='{}' and port={}".format(host, port)]
    data = []
    psql_p = subprocess.Popen(psql, stdout=subprocess.PIPE)
    for line in psql_p.stdout:
        line = line.decode('utf-8')
        data += [line.strip().split(",")]
    ecode = psql_p.wait()
    print(data)
    print(psql)
    if len(data) > 1:
        machine_id = int(data[1][0])
        return machine_id
    else:
        raise NameError("machine id not found!")
    

def call_psql(db_port, cmd=None, psqlfile=None, vars={}, getdata=False, rethandle=False, host=None):
    psql = ["psql", "-p", str(db_port), "-d", "antimony", "-U", "antimonyuser", "--csv"]

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

