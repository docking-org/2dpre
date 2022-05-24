from load_app.common.consts import *
from load_app.common.database import Database

def check_upload_history(to_be_uploaded):

	uploads_hist = []
	with open(BINDIR + '/common_files/tin_upload_history.txt') as upload_hist:
		for line in upload_hist:
			uploads_hist.append(line.strip())

	database_uploads_hist = Database.instance.select("select svalue, ivalue from meta where varname = 'upload_name' order by ivalue desc").all()
	while not uploads_hist.empty():
		upload = uploads_hist.pop()
		db_upload, db_version = database_uploads_hist.pop()
		if db_upload == upload:
			continue
		elif upload == to_be_uploaded:
			print("database is not up to date, but this upload will bring it closer!")
			return True
		else:
			raise Exception("database is not up to date!")

	return True
