from load_app.antimony.common import get_partition_id, antimony_src_dir, antimony_scratch_dir
from load_app.common.consts import *
from load_app.common.database import Database
import subprocess
import os

def upload_antimony(args):
	host = Database.instance.host
	port = Database.instance.port

	pid = get_partition_id(host, port)

	to_upload = list(filter(lambda x: x.endswith('.txt'), os.listdir(antimony_src_dir + "/" + str(pid))))
	to_upload = ["/".join([antimony_src_dir, str(pid), e]) for e in to_upload]
	if len(to_upload) == 0:
		print("already up to date!")
		return True

	source_filename = antimony_scratch_dir + "/antimony_{}_upload.txt".format(pid)
	source_file = open(source_filename, 'w')

	subprocess.call(["cat"] + to_upload, stdout=source_file)
	source_file.close()

	psqlvars = { "source_f" : source_filename }
	code = Database.instance.call_file(BINDIR + "/psql/antimony/antimony_upload.pgsql", vars=psqlvars)
	os.remove(source_filename)
	if code == 0:
		subprocess.call(["gzip"] + to_upload)
		print("success!")
		return True
	return False
