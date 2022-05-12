import subprocess

class SelectRow:
    def __init__(self, header, data):
        for h, d in zip(header, data):
            setattr(self, h, d)

class SelectResult:
    def __init__(self):
        pass

    def _code_no_load_from_sp(self, sp, echo=True):
        data = sp.stdout.read().decode('utf-8')
        if echo:
            for l in data.split("\n"):
                print(l)
        if "ROLLBACK" in data:
            sp.wait()
            self.code = 1
        else:
            self.code = sp.wait()

    def _load_from_sp(self, sp):
        self.data = []
        code = 0
        first = True
        for line in sp.stdout:
            line = line.decode('utf-8')
            if first:
                self.header_info = line.split(',')
                first = False
                continue
            self.data.append(SelectRow(self.header_info, line.split(',')))
        ecode = sp.wait()
        if code == 0 and not ecode == code:
            code = ecode
        self.code = code

    def empty(self):
        return len(self.data) == 0

    def first(self):
        return self.data[0]

    def all(self):
        return self.data

class Database:

    def __init__(self):
        pass

    def __init__(self, host, port, user, db):
        self.host = host
        self.port = port
        self.user = user
        self.db = db

    def __open_psql_sp(self, vars, addtl_args, sp_kwargs):
        psql = ["psql", "-h", str(self.host), "-p", str(self.port), "-d", self.db, "-U", self.user, "--csv"]
        for vname, vval in zip(vars.keys(), vars.values()):
            psql += ["--set={}={}".format(vname, vval)]
        psql += addtl_args
        return subprocess.Popen(psql, stdout=subprocess.PIPE, **sp_kwargs)

    def call(self, query, vars={}, echo=True, exc=False, sp_kwargs={}):
        p = self.__open_psql_sp(vars, ["-c", query], sp_kwargs)

        res = SelectResult()
        res._code_no_load_from_sp(p, echo=echo)
        if not exc:
            return res.code
        elif res.code == 0:
            return 0
        else:
            raise Exception(f"database exception code={res.code} query={query}")
        return res.code

    def select(self, query, vars={}, exc=False, sp_kwargs={}):
        p = self.__open_psql_sp(vars, ["-t", "-c", query], sp_kwargs)

        res = SelectResult()
        res._load_from_sp(p)
        if not exc:
            return res
        elif res.code == 0:
            return res
        else:
            raise Exception(f"database exception code={res.code} query={query}")
        return res

    def call_file(self, filename, vars={}, echo=True, exc=False, sp_kwargs={}):
        p = self.__open_psql_sp(vars, ["-f", filename], sp_kwargs)

        res = SelectResult()
        res._code_no_load_from_sp(p, echo=echo)
        if not exc:
            return res.code
        elif res.code == 0:
            return 0
        else:
            raise Exception(f"database exception code={res.code} query={query}")
        return res.code

    def select_file(self, filename, vars={}, exc=False, sp_kwargs={}):
        p = self.__open_psql_sp(vars, ["-t", "-f", filename], sp_kwargs)

        res = SelectResult()
        res._load_from_sp(p)
        if not exc:
            return res
        elif res.code == 0:
            return res
        else:
            raise Exception(f"database exception code={res.code} query={query}")
        return res

    def set_instance(host, port, user, db):
        setattr(Database, 'instance', Database(None, None, None, None))
        Database.instance.host = host
        Database.instance.port = port
        Database.instance.user = user
        Database.instance.db = db
