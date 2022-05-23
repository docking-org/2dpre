from load_app.antimony.common import get_partition_id, antimony_src_dir, antimony_scratch_dir
from load_app.common.consts import *
from load_app.common.upload import *
from load_app.common.database import Database
import subprocess
import os

def create_source_file(pid):
	to_upload = list(filter(lambda x: x.endswith('.txt'), os.listdir(antimony_src_dir + "/" + str(pid))))
	to_upload = ["/".join([antimony_src_dir, str(pid), e]) for e in to_upload]
	if len(to_upload) == 0:
		raise Exception("antimony already up to date!")
	source_filename = antimony_scratch_dir + "/antimony_{}_upload.txt".format(pid)
	source_file = open(source_filename, 'w')
	subprocess.call(["cat"] + to_upload, stdout=source_file)
	source_file.close()
	return source_filename

def finalize_upload(pid):
	to_upload = list(filter(lambda x: x.endswith('.txt'), os.listdir(antimony_src_dir + "/" + str(pid))))
	to_upload = ["/".join([antimony_src_dir, str(pid), e]) for e in to_upload]
	subprocess.call(["gzip"] + to_upload)

def partition_and_upload_input_data(pid):

    source_f = create_source_file(pid)
    n_partitions = get_partitions_count()

    Database.instance.call("drop table if exists temp_load_p1")
    Database.instance.call("create table temp_load_p1 (supplier_code text, last4hash char(4), cat_content_id bigint, machine_id_fk smallint) partition by hash(supplier_code)")
    make_hash_partitions("temp_load_p1", n_partitions)

    Database.instance.call("drop table if exists temp_load_p2");
    Database.instance.call("create table temp_load_p2 (sup_id bigint, cat_content_id bigint, machine_id_fk smallint) partition by hash(sup_id)")
    make_hash_partitions("temp_load_p2", n_partitions)

    source_file = open(source_f, 'r')
    code = Database.instance.call("copy temp_load_p1 from STDIN delimiter ' '", sp_kwargs={"stdin" : source_file})
    if not code == 0:
        raise NameError("failed to copy in data!")

    Database.instance.call("analyze temp_load_p1")
    return n_partitions

def upload_partitioned(stage, partition_index, transaction_identifier, diff_destination):

    psqlvars = {}
    psqlvars["stage"] = stage
    psqlvars["part"] = partition_index
    psqlvars["transid"] = transaction_identifier
    psqlvars["diff_file_dest"] = diff_destination

    code = Database.instance.call_file(BINDIR + '/psql/tin_partitioned_upload.pgsql', vars=psqlvars)
    if code == 0:
        return True
    else:
        raise NameError("upload step failed @ {},{}".format(3, partition_index))

def emulate_upload(args):
    diff_destination = args.diff_destination

    subprocess.call(["mkdir", "-p"] + [diff_destination + diff_bucket for diff_bucket in ["/codes", "/codesmap"]])
	subprocess.call(["chmod", "777"] + [diff_destination + diff_bucket for diff_bucket in ["/codes", "/codesmap"]])

    transaction_identifier = "_".join(cat_shortnames)
    
    n_partitions = get_partitions_count()

	pid = get_partition_id(host, port)
    if not check_transaction_started(transaction_identifier):
        partition_and_upload_input_data(pid)
        if not create_transaction_record_table(transaction_identifier):
            return False

    for i in range(n_partitions):
        print(1, i)
        if check_transaction_record(transaction_identifier, 1, i):
            continue
        upload_partitioned(1, i, transaction_identifier, diff_destination)
	if not check_transaction_record(transaction_identifier, 2, 0):
		# change the name of the column so the "automated" upload procedure recognizes sup_id_fk as the target column
		Database.instance.call("alter table temp_load_p2 alter column sup_id rename to sup_id_fk")
    for i in range(n_partitions):
        print(2, i)
        if check_transaction_record(transaction_identifier, 2, i):
            continue
        upload_partitioned(2, i, transaction_identifier, diff_destination)

	finalize_upload(pid)
	print("all done!")
    return True
