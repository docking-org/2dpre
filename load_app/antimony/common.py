import subprocess

BINDIR = os.path.dirname(sys.argv[0]) or '.'
BIG_SCRATCH_DIR = "/local2/load"

def call_psql(db_port, cmd=None, psqlfile=None, vars={}, getdata=False, rethandle=False):
    psql = ["psql", "-p", str(db_port), "-d", "antimony", "-U", "tinuser", "--csv"]

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
