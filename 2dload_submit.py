from load_app.common.database import Database
from load_app.tin.common import get_tin_machines
from load_app.antimony.common import get_antimony_machines
from load_app.common.consts import *
load_2d = __import__('2dload')

import sys, os, logging, subprocess, io, tempfile, time, pwd, signal
from itertools import groupby
from operator import attrgetter

parser = load_2d.create_2dload_parser(just_validate=True)
parser.add_argument("--machines", required=False, default='', help="list of machines to evaluate, defaults to all machines. expected format: {host}:{port} separated by commas")

def filter_args(args, option):
	option_full = list(filter(lambda x: x.startswith(option), args))
	option_full = None if len(option_full) == 0 else option_full[0]
	if option_full and not '=' in option_full: # filter out the next argument (which will be the value) if there is no = assignment in the argument
		option_idx = args.index(option_full)
		return args[:option_idx] + args[option_idx+2:]
	return list(filter(lambda x:not x.startswith(option), args))
cmd_args = filter_args(sys.argv[1:], '--port')
args = parser.parse_args(cmd_args)
cmd_args = filter_args(cmd_args, '--machines')

saved_squeue_data = None
with subprocess.Popen(["squeue", "-o",  "%i %j %T %M", "-u", pwd.getpwuid(os.getuid())[0]], stdout=subprocess.PIPE) as sq_sp:
	saved_squeue_data = sq_sp.stdout.readlines()

def get_job_name(subsystem, host, port, optype=None, trans_id=None):
	return 'z22_' + '_'.join([subsystem, host, port] + ([optype.replace('_', '.')] if optype else []) + ([trans_id.replace('_', '.')] if trans_id else []))
def is_job_running(subsystem, host, port):
	name = get_job_name(subsystem, host, port)
	for line in saved_squeue_data:
		line = line.decode('utf-8').strip()
		job_id, job_name, job_status, job_duration = line.split()
		namebits = job_name.split('_')
		optype = 'unknown' if len(namebits) <= 4 else namebits[4]
		trans_id = 'unknown' if len(namebits) <= 5 else namebits[5]
		if job_name.startswith(name):
			return True, optype, job_id, job_status, job_duration, trans_id
	return False, None, None, None, None, None

# will synchronize all upload, upload_zincid, groupnorm operations
def synchronize_all(preprocessing_dir, diff_destination, tarball_ids, exclude):
	present_mandatory, missing_mandatory, present_optional, missing_optional, valid_optional, id_to_optype = check_upload_history()
	pass

stop = False
def handle_int(sig, frame):
	global stop
	stop = True
signal.signal(signal.SIGINT, handle_int)

all_machines = []
valid_m = []
invalid_m = []
if args.machines:
	all_machines = [(e.split(':')[0], e.split(':')[1]) for e in args.machines.split(',')]	
else:
	if args.subsystem == 'tin':
		all_machines = get_tin_machines()
	else:
		all_machines = get_antimony_machines()


for hostname, hostname_group in groupby(list(all_machines), lambda x:x[0]):	
	
	if stop:
		break
	to_submit = []
	for hostname, port in hostname_group:
		setattr(args, 'port', int(port))
		Database.set_instance(hostname, port, args.subsystem + 'user', args.subsystem)
		
		logstr = ''
		logjob = ''
		try:
			logstr = '{}:{}:::validation ok'.format(hostname, port)
			is_running, optype, job_id, status, duration, trans_id = is_job_running(args.subsystem, hostname, port)
			
			if not is_running:
				
				# args.func(args)
				
				to_submit.append((hostname, port))
				valid_m.append((hostname, port))
				
			else:
				logjob = ':::job is running type={} transaction={} id={} status={} duration={}'.format(optype, trans_id, job_id, status, duration)

				# args.func(args)
				valid_m.append((hostname, port))
			logging.info(logstr + logjob)
		except Exception as e:
			logstr = '{}:{}:::validation fail:{}'.format(hostname, port, repr(e))
			logging.info(logstr+logjob)
			invalid_m.append((hostname, port))
		if stop:
			break
	print()
	if stop:
		break
	submit_id_prev = None
	if args.op_type == 'NOP':
		continue
	if args.op_type == "export":
		args.op_type += '.' + args.export_type
	for hostname, port in to_submit:
		slurm_base_args = ["sbatch", "-J", get_job_name(args.subsystem, hostname, port, args.op_type, args.transaction_id), "-w", hostname, "--parsable"]
		#"z22_{}_{}_{}_{}_{}".format(args.subsystem, hostname, port, args.op_type, args.transaction_id), "-w", hostname, "--parsable"]
		slurm_resource_args = ["-c", "20"]
		slurm_log_args = ["-o", f'{LOGDIR}/{args.subsystem}/{args.op_type}/{args.transaction_id}/{hostname}:{port}.out']
		os.system(f"mkdir -p {os.path.dirname(slurm_log_args[1])}")
		deps_arg = [] if not submit_id_prev else ["--dependency=afterany:{}".format(submit_id_prev)]
		script_arg = ["{}".format(sys.executable), BINDIR+'/2dload.py', "--port={}".format(port)] + cmd_args
		slurm_command = slurm_base_args+deps_arg+slurm_resource_args+slurm_log_args
		print('echo \"#\\!/bin/bash\\\n'+' '.join(script_arg)+'\" | '+' '.join(slurm_command))
		with tempfile.NamedTemporaryFile(mode='w+') as tf:
			tf.write('#!/bin/bash\n'+' '.join(script_arg)+'\n')
			tf.seek(0)
			with subprocess.Popen(slurm_command, stdout=subprocess.PIPE, stdin=tf) as subp:
				job_id = subp.stdout.read().decode('utf-8')
				job_id = job_id.strip().split(':')[0]
		logging.info('{},{}:::submitted:{}'.format(hostname, port, job_id))
		submit_id_prev = job_id
		if stop:
			break

logging.info('{} valid_m, {} invalid_m, {} total'.format(len(valid_m), len(invalid_m), len(valid_m) + len(invalid_m)))
logging.debug(valid_m, invalid_m)
