from load_app.common.consts import *
from load_app.tin.common import *
from load_app.common.upload import increment_version

import os, logging, time

def groupnorm(args):
	#diff_destination = "{}/{}/{}:{}".format(args.diff_destination, args.transaction_id, args.host, args.port)
	#os.system("mkdir -p {}/delsub".format(diff_destination))
	#os.system("chmod 777 {}/delsub".format(diff_destination))
	logging.info('starting groupnorm operation!')
	code = Database.instance.call_file(BINDIR+'/psql/tin/find_substance_groups.pgsql')
	if not code == 0:
		raise Exception('groupnorm failed!')
	increment_version(args.transaction_id)

def groupnorm_new(args):
	logging.info('starting groupnorm operation!')
	curr_iter = Database.instance.select("select ivalue from meta where varname = 'grouping_iter' and svalue = '{}'".format(args.transaction_id))
	if curr_iter.empty():
		curr_iter = 0
	else:
		curr_iter = int(curr_iter.first()[0])
	while True:
		print('curr_iter={}'.format(curr_iter))
		code = Database.instance.call_file(BINDIR+'/psql/tin/find_substance_groups_new.pgsql', vars={'transaction_id':args.transaction_id})
		if not code == 0:
			raise Exception('groupnorm failed!')
		done = Database.instance.select("select true from meta where varname = 'done_grouping' and svalue = '{}'".format(args.transaction_id))
		if done.empty():
			curr_iter += 1
		else:
			break
	increment_version(args.transaction_id)
	logging.info('groupnorm succeeded!')
