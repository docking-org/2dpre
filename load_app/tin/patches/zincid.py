from load_app.common.consts import BINDIR
from load_app.common.patches import StagedPatch

class ZincIdPartitionPatch(StagedPatch):

	def __init__(self):
		super().__init__('zincid', BINDIR + '/psql/tin/patches/zincid_partitioned')
		self.patch_stages.append('code', {})
		self.patch_stages.append('apply', {})
        self.patch_stages.append('test', {})