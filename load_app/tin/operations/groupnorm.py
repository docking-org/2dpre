from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import increment_version

import os, logging

def groupnorm(args):
	#diff_destination = "{}/{}/{}:{}".format(args.diff_destination, args.transaction_id, args.host, args.port)
	#os.system("mkdir -p {}/delsub".format(diff_destination))
	#os.system("chmod 777 {}/delsub".format(diff_destination))
	logging.info('starting groupnorm operation!')
	code = Database.instance.call_file(BINDIR+'/psql/tin/find_substance_groups.pgsql')
	if not code == 0:
		raise Exception('groupnorm failed!')
	increment_version(args.transaction_id)
