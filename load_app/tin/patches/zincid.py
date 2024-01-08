from load_app.common.consts import *
from load_app.common.patch import StagedPatch, Patch
from load_app.common.database import Database

class ZincIdPartitionPatch(StagedPatch):

	def __init__(self):
		super().__init__('zincid', BINDIR + '/psql/tin/patches/zincid_partitioned')
		self.patch_stages.append(('code', {}))
		self.patch_stages.append(('apply', {}))
		self.patch_stages.append(('test', {}))
		if Patch.get_patch_attribute('zincid'):
			self.set_patched(True, suffix='apply')
			Database.instance.call("delete from patches where patchname = 'zincid'")
