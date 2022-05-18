from load_app.common.consts import BINDIR, TARGET_PARTITION_SIZE
from load_app.common.patch import StagedPatch, Patch
from load_app.common.database import Database

import math

class TinPartitionPatch(StagedPatch):

	def __init__(self):
		super().__init__('partition', BINDIR + '/psql/tin/patches/partition')
		self.patch_stages.append(('code', {}))
		curr_table_size = int(Database.instance.select("select pg_total_relation_size('substance') as size").first()[0])
		n_partitions_to_make = 2**math.ceil(math.log(max(2, curr_table_size/TARGET_PARTITION_SIZE), 2))
		self.patch_stages.append(('apply', {'n_partitions' : n_partitions_to_make}))
		if Patch.get_patch_attribute('partition'):
			self.set_patched(True, suffix='apply')
			Database.instance.call("delete from patches where patchname = 'partition'")
