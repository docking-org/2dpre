import os, sys

target_conf = sys.argv[1]
existing_conf = sys.argv[2]

conf_map = {}
with open(target_conf) as tcnf:
	for line in tcnf:
		if line.startswith('#'):
			continue
		tokens = line.split()
		assert(tokens[1] == "=")
		if tokens[0].strip() == "shared_buffers":
			conf_map[tokens[0].strip()] = os.getenv('free_mem_mb_25')+'MB'
			continue
		conf_map[tokens[0].strip()] = tokens[2].strip()

npartitions = int(os.getenv('npartitions') or '0')
if npartitions > 128: # give some more lock space to larger databases
	conf_map['max_locks_per_transaction'] = '512'

with open(existing_conf) as excnf:

	for line in excnf:

		tokens = line.split()
		if len(tokens) == 0:
			print()
			continue
		if tokens[0].startswith("#"):
			confkey = tokens[0][1:].strip()
		else:
			confkey = tokens[0]
		if conf_map.get(confkey):
			towrite = "{} = {}".format(confkey, conf_map[confkey])
			print(towrite)
		else:
			print(line, end='')
