import os
import sys
import gzip
import subprocess
from datetime import datetime
from load_app.tin.common import BINDIR
from load_app.tin.common import call_psql as tin_call_psql
from load_app.tin.common import get_version as tin_get_version
from load_app.antimony.common import antimony_src_dir, antimony_stage_dir, antimony_partition_map, num_digits, get_machine_id

# exporting to antimony is a two-step process
# the first step is to export all supplier codes from a database (or new codes from a database upload operation) and calculate their hashed value
# this hashed value of the supplier_code serves as the key we will be using to partition the supplier codes into distributed databases
#    to use the hashed value as a key, we take the first N digits of the hash and use that to create "buckets" for the supplier codes
#    to save on space, we only export the last 4 digits of the hashed value from the database. so really we are taking the first N digits of the last 4 digits of the hash 
# 
# the second step is to sort the exported supplier codes from the database into their respective buckets
# the split files will serve as the raw files to be uploaded to antimony partitions
def export_all_from_tin(hostname, port):

        #hostname = os.uname()[1]
        machine_stage_dir = antimony_stage_dir + "/" + hostname + "_" + str(port)
        subprocess.call(["mkdir", "-p", machine_stage_dir])
        subprocess.call(["chmod", "777", machine_stage_dir])

        # implemented a versioning system for tin so that we don't get confused about which export is what
        tin_version = tin_get_version(port)
        dest = machine_stage_dir + "/" + str(tin_version) + ".txt"

        if os.path.exists(dest + ".gz"):
                print("found an existing full export @ {}. It seems to have completed, if you wish to re-export please delete the file and try again. Be careful!".format(dest + '.gz'))
                return False
        elif os.path.exists(dest + ".save"):
                print("using save file")
                os.rename(dest + '.save', dest)
                return split_antimony_partitions(hostname, port, dest, suffix=str(tin_version))
        elif os.path.exists(dest):
                #split_antimony_partitions(hostname, port, dest, suffix=str(tin_version))
                print("found an existing full export @ {}. It doesn't seem to have completed, but this process will abort anyhow. If you wish to export delete the file and try again.".format(dest))
                return False

        psqlvars = {
                        "output_file" : dest
        }
        code = tin_call_psql(port, psqlfile=BINDIR + "/psql/tin_antimony_export.pgsql", vars=psqlvars)

        if code != 0:
                print("failed!")
                if os.path.exists(dest):
                        os.remove(dest)
                return False

        split_antimony_partitions(hostname, port, dest, suffix=str(tin_version))

def split_antimony_partitions(hostname, port, rawfile, suffix=None):
        # hostname = os.uname()[1].split(".")
        if not suffix:
                suffix = datetime.isoformat(datetime.today()).replace(":", "_")

        # now we split the exported file into each antimony partition in a separate directory
        machine_id = get_machine_id(hostname, port)
        destsuffix = hostname + "_" + str(port) + "_" + suffix + ".txt"
        with open(rawfile, 'r') as export_f:

                lastlast4hash = None
                destination = None
                destination_file = None
                for line in export_f:

                        tokens = line.strip().split()

                        supplier_code = tokens[0]
                        # the file is exported from postgres ordered by the last4hash, so we don't need to worry about excessively opening and closing files
                        # at maximum the number of files opened/closed is equal to the number of partitions (e.g 64)
                        last4hash = tokens[1]
                        cat_content_id = tokens[2]

                        if last4hash != lastlast4hash:
                                # num_digits indicates how many of the hash digits serve as the partition key
                                # e.g: if the last4hash is a2g6, num_digits=2 indicates that we use "a2" as the hash key
                                # for the conceivable future, num_digits=2 will be all we need, since that gives us a capacity of 256 partitioned databases
                                # later on, we may need to expand this for > 256 partitions
                                # scaling the system may be difficult. For example- if we wanted to expand from 64 databases -> 128
                                # Each existing database would need to be split into two, which would be difficult to accomplish without some downtime
                                # Definitely possible, but during the operation the "old" databases would need to stay live until completion
                                hashkey = last4hash[:num_digits]

                                newdestination = antimony_partition_map[hashkey]
                                if newdestination != destination:
                                        if destination_file:
                                                destination_file.close()
                                        print(antimony_src_dir, destination, destsuffix)
                                        destination_file = open(antimony_src_dir + "/" + newdestination + "/" + destsuffix, 'w')
                                        destination = newdestination

                        destination_file.write(" ".join(tokens + [str(machine_id)]) + "\n")
                        lastlast4hash = last4hash

        destination_file.close()

        # gzipping the raw file indicates it has completed splitting into partitions and is now archived
        # a similar process is followed for the split files- once they are uploaded to antimony they are gzipped to indicate they have been uploaded
        # this has the two-fold benefit of creating a marker for progress and reducing the disk footprint of the files
        subprocess.call(["gzip", rawfile])
        return True
