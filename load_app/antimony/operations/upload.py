from load_app.antimony.common import get_partition_id, antimony_src_dir, antimony_scratch_dir
from load_app.common.consts import *
from load_app.common.upload import *
from load_app.common.database import Database
import subprocess
import os

def create_source_file(pid, transaction_identifier):
    
    to_upload = list(filter(lambda x: x.endswith('.txt'), os.listdir(antimony_src_dir + "/" + transaction_identifier +'/'+ str(pid))))
   
    to_upload = ["/".join([antimony_src_dir, transaction_identifier, str(pid), e]) for e in to_upload]
    if len(to_upload) == 0:
        raise Exception("antimony already up to date!")
    # source_filename = antimony_scratch_dir + "/antimony_{}_upload.txt".format(pid)
    # source_file = open(source_filename, 'w')
    
    #subprocess.call(["cat"] + to_upload, stdout=source_file)
    # source_file.close()
    #return source_filename, to_upload
    return to_upload

def finalize_upload(pid, transaction_identifier):
    to_upload = list(filter(lambda x: x.endswith('.txt'), os.listdir(antimony_src_dir + "/" + transaction_identifier + "/"+ str(pid))))
    to_upload = ["/".join([antimony_src_dir, transaction_identifier, str(pid), e]) for e in to_upload]
    subprocess.call(["gzip"] + to_upload)

def partition_and_upload_input_data(pid, transaction_identifier):
    # source_f, to_upload = create_source_file(pid, transaction_identifier)
    to_upload = create_source_file(pid, transaction_identifier)
    n_partitions = get_partitions_count()

    Database.instance.call("drop table if exists temp_load_p1")
    Database.instance.call("create table temp_load_p1 (supplier_code text, last4hash char(4), cat_content_id bigint, machine_id_fk smallint) partition by hash(supplier_code)")
    make_hash_partitions("temp_load_p1", n_partitions)

    Database.instance.call("drop table if exists temp_load_p2")
    Database.instance.call("create table temp_load_p2 (sup_id bigint, cat_content_id bigint, machine_id_fk smallint) partition by hash(sup_id)")
    make_hash_partitions("temp_load_p2", n_partitions)

    #lets upload each file one by one instead, i like seeing the progress
    for file in to_upload:
        print("copying in data from {}".format(file))
        source_file = open(file, 'r')
        code = Database.instance.call("copy temp_load_p1 from STDIN", sp_kwargs={"stdin": source_file})
        source_file.close()

        if not code == 0:
            raise NameError("failed to copy in data from {}. Call mom.".format(file))

    Database.instance.call("analyze temp_load_p1")
    return n_partitions

def upload_partitioned(stage, partition_index, transaction_identifier, diff_destination):

    psqlvars = {}
    psqlvars["stage"] = stage
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier
    psqlvars["diff_file_dest"] = diff_destination

    code = Database.instance.call_file(BINDIR + '/psql/antimony/antimony_upload.pgsql', vars=psqlvars)
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(stage, partition_index))

def emulate_upload(args):
    diff_destination = args.diff_destination + '/{}:{}'.format(args.host, args.port)

    subprocess.call(["mkdir", "-p"] + [diff_destination + diff_bucket for diff_bucket in ["/codes", "/codesmap"]])
    subprocess.call(["chmod", "777"] + [diff_destination + diff_bucket for diff_bucket in ["/codes", "/codesmap"]])

    transaction_identifier = args.transaction_id
    
    n_partitions = get_partitions_count()

    pid = get_partition_id(args.host, args.port)
    if not check_transaction_started(transaction_identifier):
        partition_and_upload_input_data(pid, transaction_identifier)
        if not create_transaction_record_table(transaction_identifier):
            return False

    for i in range(n_partitions):
        print(1, i)
        if check_transaction_record(transaction_identifier, 1, i):
            continue
        upload_partitioned(1, i, transaction_identifier, diff_destination)
    if not check_transaction_record(transaction_identifier, 2, 0):
        # change the name of the column so the "automated" upload procedure recognizes sup_id_fk as the target column
        Database.instance.call("alter table temp_load_p2 rename column sup_id to sup_id_fk")
    for i in range(n_partitions):
        print(2, i)
        if check_transaction_record(transaction_identifier, 2, i):
            continue
        upload_partitioned(2, i, transaction_identifier, diff_destination)

    finalize_upload(pid, transaction_identifier)
    print("all done!")
    return True
