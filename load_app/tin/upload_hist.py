from load_app.common.consts import *
from load_app.common.database import Database

def check_upload_history(to_be_uploaded):

	uploads_hist = []
	with open(BINDIR + '/common_files/tin_upload_history.txt') as upload_hist:
		for line in upload_hist:
			uploads_hist.append(line.strip())

	database_uploads_hist = Database.instance.select("select * from (select distinct on (svalue) svalue, ivalue from meta where varname = 'upload_name') t order by t.ivalue").all()

	while not len(uploads_hist) == 0:
		db_upload = None

		# there is an old "sz,mz" marker from a more primitive version of the software, and i want the ability to ignore it as it did not produce a diff
		while len(database_uploads_hist) != 0 and not db_upload in uploads_hist:
			res = database_uploads_hist.pop()
			db_upload = res[0]
			db_version = res[1]

		upload = uploads_hist.pop()

		if   len(database_uploads_hist) == 0:
			if not upload == to_be_uploaded:
				raise Exception("database is not up to date!")
			else:
				print("database is not up to date, but this upload will bring it closer!")
				return True
		elif upload != db_upload:
			raise Exception("database history out of order!")

	return True
