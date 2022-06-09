import sys, os, subprocess, argparse
import tempfile
import psycopg2
import io
import time

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

def get_tranche(zinc_id):
    hac = base62_rev(zinc_id[4])
    lgp = base62_rev(zinc_id[5])
    tranche = "H{:>02d}{}".format(hac, logp_range[lgp])
    return tranche

def get_zinc_id_partition(zinc_id):
    return tranche_map.get(get_tranche(zinc_id)) or "fake"

def get_conn_string(partition_host_port):
    host, port = partition_host_port.split(':')
    if host == os.uname()[1].split('.')[0]:
        host = "localhost"
    return "postgresql://tinuser@{}:{}/tin".format(host, port)

def get_sub_id(zinc_id):
    return base62_rev(zinc_id[8:])

def get_zinc_id(sub_id, tranche_name):
    if not tranche_name or tranche_name == "null":
        return "ZINC" + "??00" + "{:0>8s}".format(base62(sub_id))
    hac = digits[int(tranche_name[1:3])]
    lgp = digits[logp_range.index(tranche_name[3:])]
    zid = "ZINC" + hac + lgp + "00" + "{:0>8s}".format(base62(sub_id))
    return zid

# shameless steal from stackoverflow https://stackoverflow.com/questions/3173320/text-progress-bar-in-terminal-with-block-characters?noredirect=1&lq=1
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = 'X', printEnd = "\r", t_elapsed=0, projected=0):
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength_current = int(length * iteration // total)
    filledLength_project = int(length * (iteration+projected) // total)
    bar = fill * filledLength_current + '/' * (filledLength_project-filledLength_current) + '-' * (length - filledLength_project)
    t_elapsed_str = "{:> 4.2f}s".format(t_elapsed)
    print(f'\r{prefix} |{bar}| {percent}% {t_elapsed_str} {iteration}/{total} {suffix}', end = printEnd)
    # Print New Line on Complete
    if iteration == total:
        print()

def get_vendor_results(input_list, search_curs, output_file):
    search_curs.execute("create temporary table tq_ot (smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_content_id bigint, cat_id_fk smallint)")
    search_curs.execute("call get_some_pairs_by_sub_id('tq_in', 'tq_ot')")
    search_curs.execute("select smiles, sub_id, tranches.tranche_name, supplier_code, cat_content_id, catalog.short_name from tq_ot left join tranches on tq_ot.tranche_id = tranches.tranche_id left join catalog on tq_ot.cat_id_fk = catalog.cat_id")

    input_index_sub_id = None
    for result in search_curs.fetchall():
        smiles          = result[0] or "_null_"
        sub_id          = result[1]
        tranche_name    = result[2]
        supplier_code   = result[3] or "_null_"
        cat_content_id  = result[4] or "_null_"
        cat_name        = result[5] or "_null_"
        # here's the rationale: sub_ids should all be able to be found, unless they are outright bogus
        # but when there is a sub_id not found, there may be many of them. in this case we need to look the sub_id up from the input list to determine the tranche
        # in order to not have situations where the script slows to a crawl, e.g if there are a ton of ids that don't look up properly, we need to index the input list
        if not tranche_name:
            if not input_index_sub_id:
                input_index_sub_id = {}
                for i, e in enumerate(input_list):
                    sub_id = e[0]
                    if not input_index_sub_id.get(sub_id):
                        input_index_sub_id[sub_id] = [e[1]]
                    else:
                        input_index_sub_id[sub_id].append(e[1])
            matching_tranches = input_index_sub_id[sub_id]
            zinc_id = ','.join([get_zinc_id(sub_id, tranche) for tranche in matching_tranches])
            tranche_name = ','.join(matching_tranches)
        else:
            zinc_id = get_zinc_id(sub_id, tranche_name)
        output_file.write('\t'.join([smiles, zinc_id, tranche_name, supplier_code, cat_name]) + '\n')

def get_smiles_results(input_list, search_curs, output_file):
    search_curs.execute("create temporary table tq_ot (smiles text, sub_id bigint, tranche_id smallint)")
    search_curs.execute("call get_some_substances_by_id('tq_in', 'tq_ot')")
    search_curs.execute("select smiles, sub_id, tranches.tranche_name from tq_ot left join tranches on tq_ot.tranche_id = tranches.tranche_id")

    input_index_sub_id = {}
    for result in search_curs.fetchall():
        smiles          = result[0] or "_null_"
        sub_id          = result[1]
        tranche_name    = result[2]
        if not tranche_name:
            if not input_index_sub_id:
                input_index_sub_id = {}
                for i, e in enumerate(input_list):
                    sub_id_in = e[0]
                    if not input_index_sub_id.get(sub_id_in):
                        input_index_sub_id[sub_id_in] = [e[1]]
                    else:
                        input_index_sub_id[sub_id_in].append(e[1])
            matching_tranches = input_index_sub_id[sub_id]
            zinc_id = ','.join([get_zinc_id(sub_id, tranche) for tranche in matching_tranches])
            tranche_name = ','.join(matching_tranches)
        else:
            zinc_id = get_zinc_id(sub_id, tranche_name)
        output_file.write('\t'.join([smiles, zinc_id, tranche_name]) + '\n')

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="search for smiles by zinc22 id")

    parser.add_argument("zinc_id_in", type=str, help="file containing list of zinc ids to look up")
    parser.add_argument("results_out", type=str, help="destination file for output")
    parser.add_argument("--get-vendors", action='store_true', default=False, help="get vendor supplier codes associated with zinc id")
    parser.add_argument("--configuration-server-url", type=str, default="postgresql://zincuser@10.20.1.17:5534/zinc22_common", help="database containing configuration for zinc22 system")

    args = parser.parse_args()

    # all configuration prepartion
    config_conn = psycopg2.connect(args.configuration_server_url)
    config_curs = config_conn.cursor()
    config_curs.execute("select tranche, host, port from tranche_mappings")
    tranche_map = {}
    for result in config_curs.fetchall():
        tranche = result[0]
        host = result[1]
        port = result[2]
        tranche_map[tranche] = ':'.join([host, str(port)])

    zinc_ids_dict = {}

    with tempfile.NamedTemporaryFile(mode='w+') as tf:
        with open(args.zinc_id_in) as zinc_id_in:
            for zinc_id in zinc_id_in:
                zinc_id = zinc_id.strip()
                id_partition = get_zinc_id_partition(zinc_id)
                tf.write("{} {}\n".format(zinc_id, id_partition))
        tf.flush()

        with subprocess.Popen(["/bin/sort", "-k2", tf.name], stdout=subprocess.PIPE) as sort_proc:
            for line in sort_proc.stdout:
                zinc_id, p_id = line.decode('utf-8').strip().split()
                if not zinc_ids_dict.get(p_id):
                    zinc_ids_dict[p_id] = [zinc_id]
                else:
                    zinc_ids_dict[p_id].append(zinc_id)

    total_length = sum([len(z) for z in zinc_ids_dict.values()])
    curr_length = 0
    with open(args.results_out, 'w') as output_file:
        t_start = time.time()

        for p_id, zinc_ids_list in zinc_ids_dict.items():

            data_list = [(get_sub_id(z), get_tranche(z)) for z in zinc_ids_list]
            if p_id == "fake":
                print("provided a zinc id(s) that could not possibly exist! skipping!")
                for sub_id, tranche in data_list:
                    tokens = ["_null_", get_zinc_id(sub_id, tranche), tranche] + (2 if args.get_vendors else 0) * ["_null_"]
                    output_file.write('\t'.join(tokens)+'\n')
                curr_length += len(zinc_ids_list)
                continue
            try:
                search_database = get_conn_string(p_id)
                search_conn = psycopg2.connect(search_database, connect_timeout=1)
                search_curs = search_conn.cursor()
                t_elapsed = time.time() - t_start
                printProgressBar(curr_length, total_length, prefix = "Searching Zinc22: ", suffix=p_id, length=50, t_elapsed=t_elapsed, projected=len(zinc_ids_list))

                data_file = io.StringIO('\n'.join([str(z[0]) for z in data_list]))
                search_curs.execute("create temporary table tq_in (sub_id bigint)")
                search_curs.copy_from(data_file, 'tq_in', sep=',', columns=['sub_id'])
                if args.get_vendors:
                    get_vendor_results(data_list, search_curs, output_file)
                else:
                    get_smiles_results(data_list, search_curs, output_file)

            except psycopg2.OperationalError as e:
                print()
                print("failed to connect to {}, the machine is probably down. Going to continue and collect partial results.".format(search_database))
                for sub_id, tranche in data_list:
                    tokens = ["_null_", get_zinc_id(sub_id, tranche), tranche] + (2 if args.get_vendors else 0) * ["_null_"]
                    output_file.write('\t'.join(tokens) +'\n')

            finally:
                search_conn.close()
            
            curr_length += len(zinc_ids_list)

        t_elapsed = time.time() - t_start
        printProgressBar(curr_length, total_length, prefix = "Searching Zinc22: ", suffix="complete!", length=50, t_elapsed=t_elapsed)

    
