from load_app.antimony.common import *

def upload_antimony(port, source_file):

	psqlvars = { "source_f" : source_file }
	call_psql(port, psqlfile=BINDIR + "/antimony/antimony_upload.pgsql", vars=psqlvars)
