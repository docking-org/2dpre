from load_app.common.consts import *
from load_app.tin.common import *

import os, logging

def blast_dups_substance(args):
	diff_destination = "{}/{}/{}:{}".format(args.diff_destination, args.transaction_id+'_blast_substance', args.host, args.port)
	os.system("mkdir -p {}/delsub".format(diff_destination))
	os.system("chmod 777 {}/delsub".format(diff_destination))
	logging.info('starting blast operation!')
	Database.instance.call_file(BINDIR+'/psql/tin/blast_dups.pgsql', vars={'diff_destination':diff_destination})
