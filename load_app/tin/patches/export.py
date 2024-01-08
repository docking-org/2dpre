from load_app.common.patch import StagedPatch
from load_app.common.consts import BINDIR

class ExportPatch(StagedPatch):
	def __init__(self):
		super().__init__('export', BINDIR + '/psql/tin/patches/export')
		self.patch_stages.append(('code', {}))
		self.patch_stages.append(('test', {}))
