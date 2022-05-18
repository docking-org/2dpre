from load_app.common.database import Database
from load_app.common.consts import *
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

	def get_patch_attribute(patchname):
		res = Database.instance.select("select patched from patches where patchname = '{}'".format(patchname))
		if res.code == 0:
			if res.empty():
				return False
			else:
				return True if res.first()[0] == 't' else False
		return False

	def set_patch_attribute(patchname, patchvalue):
		patchvalue_psqlstr = 'true' if patchvalue else 'false'
		res = Database.instance.select("update patches set patched = {} where patchname = '{}' returning *".format(patchvalue_psqlstr, patchname))
		print(res, res.data)
		if len(res.data) <= 1: # for some f**king reason, UPDATE 0 still gets echoed in "tuples only" mode, so account for that
			Database.instance.call("insert into patches (values ('{}', {}))".format(patchname, patchvalue_psqlstr))

	def is_patched(self, suffix=''):
		name = '_'.join([self.name] + [suffix] if suffix else [])
		return Patch.get_patch_attribute(name)

	def set_patched(self, value, suffix=''):
		name = '_'.join([self.name] + [suffix] if suffix else [])
		Patch.set_patch_attribute(name, value)

class PatchPatch(Patch):

	def __init__(self):
		super().__init__('patch')

	def is_patched(self, suffix=''):
		if suffix != '':
			return super().is_patched(suffix=suffix)
		return super().is_patched(suffix='patchtable') and super().is_patched(suffix='meta')

	def apply(self, verbose=False):
		if self.is_patched():
			return

		if not self.is_patched(suffix='patchtable'):
			code = Database.instance.call("create table if not exists patches (patchname text, patched boolean)")
			self.set_patched(True, suffix='patchtable')

		if not self.is_patched(suffix='meta'):
			Database.instance.call("alter table if exists tin_meta rename to meta")# fix tin meta table name else create the meta table
			code = Database.instance.call("create table meta (varname text, svalue text, ivalue bigint)")
			if code == 0:
				Database.instance.call("insert into meta(varname, ivalue) values ('version', 0)", exc=True)
				Database.instance.call("insert into meta(varname, ivalue, svalue) values ('upload_name', 0, null)", exc=True)
			self.set_patched(True, suffix='meta')

class StagedPatch(Patch):

	def __init__(self, name, codepath):
		super().__init__(name)
		self.codepath = codepath
		self.patch_stages = []

	def is_patched(self, suffix=''):
		if suffix:
			return super().is_patched(suffix=suffix)
		patched = True
		for stage_name, var_args in self.patch_stages:
			patched = patched and super().is_patched(suffix=stage_name)
		return patched

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

class UploadPatch(StagedPatch):

	def __init__(self):
		super().__init__('upload', BINDIR + '/psql/common/patches/upload')
		self.patch_stages.append(('code', {}))
		self.patch_stages.append(('test', {}))
