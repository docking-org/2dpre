from load_app.tin.common import BINDIR, call_psql, set_patched

def patch_database_version(db_port, db_path):
	code = call_psql(db_port, cmd="create table tin_meta(varname varchar, svalue varchar, ivalue int)")
	if code != 0:
		return False
	code = call_psql(db_port, cmd="insert into tin_meta(varname, ivalue) values ('version', 0)")
	if code != 0:
		return False
	code = call_psql(db_port, cmd="insert into tin_meta(varname, ivalue, svalue) values ('upload_name', 0, null)")
	if code != 0:
		return False

	set_patched(db_port, "version", True)
	return True
