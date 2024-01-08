from load_app.common.consts import BINDIR
from load_app.common.patch import StagedPatch
from load_app.common.database import Database

class AntimonyPartitionPatch(StagedPatch):

	def __init__(self):
		super().__init__('partition', BINDIR + '/psql/antimony/patches/partition')
		self.patch_stages.append(('code', {}))
		self.patch_stages.append(('apply', {'n_partitions' : 128}))
