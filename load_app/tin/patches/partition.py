from load_app.tin.common import get_tranches, zincid_to_subid_opt, get_tranche_id, call_psql, BINDIR, set_patched
import os, sys, subprocess, math

class PartitionPatch(Patch):

	def __init__(self, name):


def patch_database_partition(port):

	# aim for ~512MB per substance table partition, going up in multiples of 2 partitions, e.g 1, 2, 4, 8, 16, 32, 64, 128, 256, 512 etc...
	target_p_size = 512000000
	curr_table_size = int(call_psql(port, "select pg_total_relation_size('substance')", getdata=True)[1][0])
	print(curr_table_size);
	n_partitions_to_make = 2**math.ceil(math.log(max(2, curr_table_size/target_p_size), 2))
	print("going to make {} partitions!".format(n_partitions_to_make))

	for table in ["substance_t", "catalog_content_t", "catalog_substance_t", "catalog_substance_cat_t"]:
		call_psql(port, "drop table if exists {}".format(table))

	code = 0
	code |= call_psql(port,"create table substance_t (like substance including defaults) partition by hash(smiles)")
	code |= call_psql(port,"create table catalog_content_t (like catalog_content including defaults) partition by hash(supplier_code)")
	code |= call_psql(port,"create table catalog_substance_t (like catalog_substance including defaults) partition by hash(sub_id_fk)")
	code |= call_psql(port,"create table catalog_substance_cat_t (like catalog_substance including defaults) partition by hash(cat_content_fk)")
	if code != 0:
		print("failed to create tables!")
		return False

	for i in range(n_partitions_to_make):
		print("{}/{}".format(i+1, n_partitions_to_make), end="\r")
		code = 0
		code |= call_psql(port, "create table substance_tp{} partition of substance_t for values with (modulus {}, remainder {})".format(i, n_partitions_to_make, i))
		code |= call_psql(port, "create table catalog_content_tp{} partition of catalog_content_t for values with (modulus {}, remainder {})".format(i, n_partitions_to_make, i))
		code |= call_psql(port, "create table catalog_substance_tp{} partition of catalog_substance_t for values with (modulus {}, remainder {})".format(i, n_partitions_to_make, i))
		code |= call_psql(port, "create table catalog_substance_cat_tp{} partition of catalog_substance_cat_t for values with (modulus {}, remainder {})".format(i, n_partitions_to_make, i))
		if code != 0:
			print("failed to create partitions!")
			return False

	code = call_psql(port, psqlfile=BINDIR + '/psql/tin_partition_patch.pgsql')

	success = False
	if code == 0:
		call_psql(port, "insert into tin_meta(svalue, ivalue) (values ('n_partitions', {}))".format(n_partitions_to_make))
		set_patched(port, "partition", True)
		success = True
	return success

