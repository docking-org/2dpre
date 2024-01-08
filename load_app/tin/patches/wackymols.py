from load_app.common.patch import StagedPatch
from load_app.common.consts import BINDIR

class WackyMolsPatch(StagedPatch):
	def __init__(self):
		super().__init__('wackymols', BINDIR + '/psql/tin/patches/wackymols')
		self.patch_stages.append(('apply', {}))
