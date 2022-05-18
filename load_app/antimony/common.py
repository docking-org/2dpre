import subprocess
import os, sys

from load_app.common.consts import *
from load_app.common.database import Database

#from load_app.antimony.common import antimony_src_dir, antimony_stage_dir, antimony_partition_map, num_digits, get_machine_id
# get_partition_id

num_digits = 2
antimony_scratch_dir = "/local2/load"
antimony_src_dir = "/nfs/exh/zinc22/antimony/src"
antimony_stage_dir = "/nfs/exh/zinc22/antimony/stage"

common_db = Database('n-1-17', 5534, 'zincuser', 'zinc22_common')
antimony_machine_partition_map = {}
antimony_partition_map = {}

with open(BINDIR + "/load_app/antimony/machine_partition_map.txt") as pmapf:
    for line in pmapf:
        tokens = line.strip().split()
        antimony_machine_partition_map[tokens[0] + ":" + tokens[1]] = tokens[2]

with open(BINDIR + "/load_app/antimony/hash_partition_map.txt") as pmapf:
    for line in pmapf:
        tokens = line.strip().split()
        antimony_partition_map[tokens[0]] = tokens[1]

def get_partition_id(host, port):
    return antimony_machine_partition_map[host + ":" + str(port)]

def get_machine_id(host, port):
    res = common_db.select("select machine_id from tin_machines where hostname='{}' and port={}".format(host, port))
    if res.empty():
        raise NameError("machine id not found!")
    else:
        return int(res.first()[0])
