from load_app.tin.common import *
from load_app.antimony.common import ANTIMONY_SOURCE_DIR
import os
import sys



def tin_export_antimony(port):

	output = BIG_SCRATCH_DIR + "/" + "_".join([host, str(port), "antimonysrc"])
	psqlvars = { "output_file" : output, "machine_id" :  }

	code = call_psql(port, psqlfile=BINDIR + "/psql/tin_antimony_export.pgsql", vars=psqlvars)
	if not code == 0:
		print("something went wrong!")
		sys.exit(1)

	
