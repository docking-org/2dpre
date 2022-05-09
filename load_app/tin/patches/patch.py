from load_app.tin.common import Database

class Patch:

	def __init__(self):
		self.name = 'patch'

	def apply(self):
		if Database.instance.call("create table patches (patchname text, patched boolean)"):
			Database.instance.call("insert into patches (values ('patch', true))")
		return True

	@staticmethod
	def get_patch_attribute(patchname):
		res, retcode = Database.instance.select("select patched from patches where patchname = '{}'".format(patchname))
		if retcode == 0:
			return True if res.data[0][0] == 't' else False
		return False

	@staticmethod
	def set_patch_attribute(patchname, patchvalue):
		patchvalue_psqlstr = 'true' if patchvalue else 'false'
		if not Database.instance.call("update patches set patched = {} where patchname = '{}'".format(patchvalue_psqlstr, patchname))
			Database.instance.call("insert into patches (values ('{}', {}))".format(patchname, patchvalue_psqlstr))

	def is_patched(self):
		return Patch.get_patch_attribute(self.name)

	def set_patched(self, value):
		Patch.set_patch_attribute(self.name, value)


	instance = Patch()
