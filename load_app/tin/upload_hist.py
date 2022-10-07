from load_app.common.consts import *
from load_app.common.database import Database

def clean_up_meta_table():

	Database.instance.call("drop table if exists meta_save")
	Database.instance.call("create table meta_save (svalue text, ivalue int)")
	Database.instance.call("insert into meta_save (svalue, ivalue) (select svalue, mi from (select svalue, min(ivalue) mi from meta where varname = 'upload_name' and svalue != '' group by varname, svalue) t order by mi)")
	Database.instance.call("delete from meta where varname = 'upload_name'")
	Database.instance.call("insert into meta (varname, svalue, ivalue) (select 'upload_name', svalue, ivalue from meta_save)")
	# update version correspondingly (just in case)
	Database.instance.call("update meta set ivalue = a.ivalue from (select max(ivalue) ivalue from meta where varname = 'upload_name') a where varname = 'version'")
	# delete extra "n_partitions" entries that seem to have crept in (because they annoy me)
	Database.instance.call("delete from meta using (select min(ctid) as ctid, svalue from meta group by svalue having count(*) > 1) m where meta.svalue = 'n_partitions' and meta.svalue = m.svalue and meta.ctid <> m.ctid")
	# fix sz,mz having a comma, which borks the results we get from select (because I don't handle commas in quotation groups in the database select parsing)
	# I know- it's a bit silly that I'm writing my own library for this instead of using a pre-existing one that would handle things like this
	# but we've already gotten this far...
	Database.instance.call("update meta set svalue = replace(svalue, ',', '_') where varname = 'upload_name'")

def check_upload_history(to_be_uploaded):

	uploads_hist = []
	with open(BINDIR + '/common_files/tin_upload_history.txt') as upload_hist:
		for line in upload_hist:
			uploads_hist.append(line.strip())
	
	uploads_hist = list(reversed(uploads_hist))
	print(uploads_hist)

	clean_up_meta_table()
	database_uploads_hist = Database.instance.select("select svalue, ivalue from (select distinct on (svalue) svalue, ivalue from meta where varname = 'upload_name') t order by t.ivalue desc").all()

	while not len(uploads_hist) == 0 and not len(database_uploads_hist) == 0:
		db_upload = None

		db_upload = database_uploads_hist.pop()[0]
		upload = uploads_hist.pop()
		print(db_upload, "|||", upload, "|||", uploads_hist, database_uploads_hist)

		if upload != db_upload:
			raise Exception("database history out of order! up: {}, dbu: {}".format(upload, db_upload))

	if len(uploads_hist) == 0:
		if len(database_uploads_hist) == 0:
			raise Exception("database already up to date! if you are trying to upload a file, it must be recorded in the upload history record first")
		else:
			raise Exception("database has more uploads than are recorded in the history file!")
	# if the histories correspond up to this point, and there are more uploads to be done, then check that the set to be uploaded matches the oldest set not yet uploaded
	elif len(uploads_hist) > 0 and to_be_uploaded == uploads_hist[-1]:
		return True
	else:
		raise Exception('database history out of order! up: {}, needed: {}'.format(to_be_uploaded, uploads_hist[-1]))
