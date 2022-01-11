import os
from load_app.tin.common import call_psql, BINDIR

def apply_config(port):

	call_psql(port, psqlfile=BINDIR + '/psql/tin/config.pgsql')
