import os, sys

target_conf = sys.argv[1]
existing_conf = sys.argv[2]

conf_map = {}
with open(target_conf) as tcnf:
	for line in tcnf:
		tokens = line.split()
		assert(tokens[1] == "=")
		conf_map[tokens[0].strip()] = tokens[2].strip()

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
