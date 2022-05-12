from load_app.common.consts import BINDIR
from load_app.common.patch import StagedPatch
from load_app.common.database import Database

class TinPartitionPatch(StagedPatch):

	def __init__(self):
		super().__init__('partition', BINDIR + '/psql/tin/patches/partition')
		self.patch_stages.append(('code', {}))
		curr_table_size = int(Database.instance.select("select pg_total_relation_size('substance') as size").first().size)
		n_partitions_to_make = 2**math.ceil(math.log(max(2, curr_table_size/target_p_size), 2))
		self.patch_stages.append(('apply', {'n_partitions' : n_partitions_to_make}))
