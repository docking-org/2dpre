from load_app.common.database import Database
import sys, os

# Contains Base patch classes as well as all patches that apply to both Tin and Antimony systems

# each patch is a singleton, since the patch just encapsulates the logic for applying a patch, and shouldn't be duplicated
class Singleton(type):
    _instances = {}
    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            cls._instances[cls] = super(Singleton, cls).__call__(*args, **kwargs)
        return cls._instances[cls]

class Patch(metaclass=Singleton):

	def __init__(self, name):
		self.name = name

	@staticmethod
	def get_patch_attribute(patchname):
		res, retcode = Database.instance.select("select patched from patches where patchname = '{}'".format(patchname))
		if retcode == 0:
			if res.empty():
				return False
			else:
				return True if res.first().patched == 't' else False
		return False

	@staticmethod
	def set_patch_attribute(patchname, patchvalue):
		patchvalue_psqlstr = 'true' if patchvalue else 'false'
		if Database.instance.call("update patches set patched = {} where patchname = '{}'".format(patchvalue_psqlstr, patchname)) != 0:
			Database.instance.call("insert into patches (values ('{}', {}))".format(patchname, patchvalue_psqlstr))

	def is_patched(self, suffix=''):
		name = '_'.join(self.name, suffix)
		return Patch.get_patch_attribute(name)

	def set_patched(self, value, suffix=''):
		name = '_'.join(self.name, suffix)
		Patch.set_patch_attribute(name, value)

class PatchPatch(Patch):

	def __init__(self):
		super().__init__('patch')

	def apply(self, verbose=False):
		if self.is_patched():
			return

		if not self.is_patched(suffix='patchtable'):
			try:
				Database.instance.call("create table if not exists patches (patchname text, patched boolean) as (values ('patch', true))", exc=True)
				self.set_patched(True, suffix='patchtable')
			except:
				sys.stderr.write("encountered exception when creating patch table\n")
				raise

		if not self.is_patched(suffix='meta')
			try:
				Database.instance.call("alter table if exists tin_meta rename to meta")# fix tin meta table name else create the meta table
				Database.instance.call("create table if not exists meta (varname text, svalue text, ivalue bigint", exc=True)
				Database.instance.call("insert into meta(varname, ivalue) values ('version', 0)", exc=True)
				Database.instance.call("insert into meta(varname, ivalue, svalue) values ('upload_name', 0, null)", exc=True)
				self.set_patched(True, suffix='metatable')
			except:
				sys.stderr.write("encountered exception when creating meta table\n")
				raise

		self.set_patched(True)

	instance = PatchPatch()

class StagedPatch(Patch):

	def __init__(self, name, codepath):
		super().__init__(name)
		self.codepath = codepath
		self.patch_stages = []

	def apply(self, verbose=False):
		if self.is_patched():
			return

		for stage_name, var_args in self.patch_stages:
			if verbose:
				print(f"patching {self.name} stage={stage_name}")
			if not self.is_patched(suffix=stage_name):
				stage_pg = os.path.join(self.codepath, stage_name + '.pgsql')
				try:
					ecode = Database.instance.call_file(stage_pg, vars=var_args, exc=True)
				except:
					sys.stderr.write(f"failed {self.name} patch @ stage={stage_name}\n")
					raise
				self.set_patched(True, suffix=stage_name)

		self.set_patched(True)

class UploadPatch(StagedPatch):

	def __init__(self):
		super().__init__('upload', BINDIR + '/psql/common/patches/upload')
		self.patch_stages.append(('code', {}))
		self.patch_stages.append(('test', {}))