from load_app.common.consts import *
from load_app.common.database import Database
from load_app.tin.common import subid_to_zincid_opt
import os, sys, subprocess, shutil

def export_vendors(destination):

	export_tmp_dest = BIG_SCRATCH_DIR + "/export_{}_{}".format(Database.instance.host, Database.instance.port)
	export_raw_dest = export_tmp_dest + "/raw_vendors"
	export_raw_split_dest = export_tmp_dest + "/split_vendors"

	subprocess.call(["mkdir", "-p", export_raw_split_dest])
	subprocess.call(["chmod", "777", export_tmp_dest])

	psqlvars = {"output_file" : export_raw_dest}
	Database.instance.call_file(BINDIR + '/psql/tin/export_pairs.pgsql', vars=psqlvars)
	
	subprocess.call(["awk", "-v", "t={}".format(export_raw_split_dest), '{print>t"/"$5}', export_raw_dest])

	for tranche in os.listdir(export_raw_split_dest):
		assert(len(tranche) == 7)
		hac = tranche[:3]
		dstfile = "/".join([destination, hac, tranche]) + '.smi'
		subprocess.call(["mkdir", "-p", os.path.dirname(dstfile)])
		subid_to_zincid_opt(export_raw_split_dest + "/" + tranche, dstfile + '.t', tranche, 3)
		final_out = open(dstfile, 'w')
		subprocess.call(["awk", '{print $1 "\t" $3 "\t" $2 "\t" $6}', dstfile +'.t'], stdout=final_out)
		final_out.close()
		os.remove(dstfile + '.t')
		subprocess.call(["gzip", "-f", dstfile])

	os.remove(export_raw_dest)
	shutil.rmtree(export_raw_split_dest)
