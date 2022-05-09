from load_app.tin.common import *

def patch_database_zincid(port):

    code = call_psql(port, psqlfile=BINDIR+"/psql/tin_partitioned_zincid_patch.pgsql")

    if code == 0:
        set_patched(port, 'zincid', True)
        return True
    return False

def patch_database_catid(port):

    code = call_psql(port, psqlfile=BINDIR+"/psql/tin/patches/catid_partitioned/code.pgsql")
