from load_app.common.consts import *
class CatIdPartitionPatch(StagedPatch):

    def __init__(self):
        super().__init__('catid', BINDIR + '/psql/tin/patches/catid_partitioned')
        self.patch_stages.append('code', {})
        self.patch_stages.append('apply', {})
        self.patch_stages.append('test', {})