from load_app.common.patch import StagedPatch
from load_app.common.consts import BINDIR

class June32022Patch(StagedPatch):
	def __init__(self):
		super().__init__('june3_2022', BINDIR + '/psql/tin/patches/june3_2022')
		self.patch_stages.append(('code', {}))
