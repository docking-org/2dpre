import sys, os, subprocess, argparse
import tempfile
import psycopg2

parser = argparse.ArgumentParser()

parser.add_argument("zinc_id_in", type=str, help="file containing list of zinc ids to look up")
parser.add_argument("results_out", type=str, help="destination file for output")
parser.add_argument("--configuration-server-url", type=str, default="postgresql://zincuser@10.20.1.17:5534/zinc22_common")

args = parser.parse_args()

# all stuff related to parsing zinc ids goes here
digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
logp_range="M500 M400 M300 M200 M100 M000 P000 P010 P020 P030 P040 P050 P060 P070 P080 P090 P100 P110 P120 P130 P140 P150 P160 P170 P180 P190 P200 P210 P220 P230 P240 P250 P260 P270 P280 P290 P300 P310 P320 P330 P340 P350 P360 P370 P380 P390 P400 P410 P420 P430 P440 P450 P460 P470 P480 P490 P500 P600 P700 P800 P900".split(" ")
#logp_range_rev={e:i for i, e in enumerate(logp_range)}
digits_map = { digit : i for i, digit in enumerate(digits) }
b62_table = [62**i for i in range(12)]
def base62_rev(s):
	tot = 0
	for i, c in enumerate(reversed(s)):
		val = digits_map[c]
		tot += val * b62_table[i]
	return tot
def base62(n):
    b62_str=""
    while n >= 62:
        n, r = divmod(n, 62)
        b62_str += digits[r]
    b62_str += digits[n]
    return ''.join(reversed(b62_str))

# all configuration prepartion
config_conn = psycopg2.connect(args.configuration_server_url)
config_curs = config_conn.cursor()
config_curs.execute("select tranche, host, port from tranche_mappings")
tranche_map = {}
for result in config_curs.fetchall():
    tranche = result[0]
    host = result[1]
    port = result[2]
    tranche_map[tranche] = ':'.join([host, port])

def get_zinc_id_partition(zinc_id):
    hac = base62_rev(zinc_id[5])
    lgp = base62_rev(zinc_id[6])
    tranche = "H{:>02d}{}".format(hac, logp_range[lgp])
    return tranche_map[tranche]

def get_conn_string(partition_host_port):
    return "postgresql://tinuser@{}/tin".format(partition_host_port)

def get_sub_id(zinc_id):
    return base62_rev(zinc_id[8:])

sort_proc = subprocess.Popen(["sort", "-k2", "-"], stdin=subprocess.PIPE, stdout=subprocess.PIPE)

zinc_ids_dict = {}

with tempfile.TemporaryFile() as tf:
    with open(args.zinc_id_in) as zinc_id_in:
        for zinc_id in zinc_id_in:
            id_partition = get_zinc_id_partition(zinc_id)
            tf.write("{} {}\n".format(zinc_id, id_partition))

    with subprocess.Popen(["sort", "-k2", tf.name], stdout=subprocess.PIPE) as sort_proc:
        for line in sort_proc.stdout:
            zinc_id, p_id = line.strip().split()
            if not zinc_ids_dict.get(p_id)
                zinc_ids_dict[p_id] = [zinc_id]
            else:
                zinc_ids_dict[p_id].append(zinc_id)

# shameless steal from stackoverflow https://stackoverflow.com/questions/3173320/text-progress-bar-in-terminal-with-block-characters?noredirect=1&lq=1
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█', printEnd = "\r"):
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = printEnd)
    # Print New Line on Complete
    if iteration == total: 
        print()

total_length = sum([len(z) for z in zinc_ids_dict.values()])
curr_length = 0
with open(args.results_out, 'w') as output_file:
    for p_id, zinc_ids_list in zinc_ids_dict.items():

        search_database = get_conn_string(p_id)
        search_conn = psycopg2.connect(search_database)
        search_curs = search_conn.cursor()
        printProgressBar(curr_length, total_length, prefix = "Searching Zinc22: ", suffix=p_id, length=50)

        data_file = io.StringIO('\n'.join([str(get_sub_id(z)) for z in zinc_ids_list]))
        search_curs.execute("create temporary table tq_in (sub_id)")
        search_curs.execute("create temporary table tq_ot (smiles, sub_id, tranche_id, supplier_code, cat_content_id, cat_id_fk)")
        search_curs.execute("call get_some_pairs_by_sub_id('tq_in', 'tq_ot')")
        search_curs.execute("select smiles, sub_id, tranche_id, supplier_code, cat_content_id, cat_id_fk from tq_ot")

        for result in search_curs.fetchall():
            smiles          = result[0]
            sub_id          = result[1]
            tranche_id      = result[2]
            supplier_code   = result[3]
            cat_content_id  = result[4] # leave this out
            cat_id_fk       = result[5] # leave this out (for now)
            output_file.write('\t'.join([smiles, sub_id, tranche_id, supplier_code]) + '\n')
        
        curr_length += len(zinc_ids_list)

    
