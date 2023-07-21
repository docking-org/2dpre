from load_app.common.consts import *
from load_app.common.database import Database
import logging

def clean_up_meta_table():

	Database.instance.call("drop table if exists meta_save", echo=False)
	Database.instance.call("create table meta_save (svalue text, ivalue int)", echo=False)
	Database.instance.call("insert into meta_save (svalue, ivalue) (select svalue, mi from (select svalue, min(ivalue) mi from meta where varname = 'upload_name' and svalue != '' group by varname, svalue) t order by mi)", echo=False)
	Database.instance.call("delete from meta where varname = 'upload_name'", echo=False)
	Database.instance.call("insert into meta (varname, svalue, ivalue) (select 'upload_name', svalue, ivalue from meta_save)", echo=False)
	# update version correspondingly (just in case, echo=False)
	Database.instance.call("update meta set ivalue = a.ivalue from (select max(ivalue) ivalue from meta where varname = 'upload_name') a where varname = 'version'", echo=False)
	# delete extra "n_partitions" entries that seem to have crept in (because they annoy me, echo=False)
	Database.instance.call("delete from meta using (select min(ctid) as ctid, svalue from meta group by svalue having count(*) > 1) m where meta.svalue = 'n_partitions' and meta.svalue = m.svalue and meta.ctid <> m.ctid", echo=False)
	# fix sz,mz having a comma, which borks the results we get from select (because I don't handle commas in quotation groups in the database select parsing, echo=False)
	# I know- it's a bit silly that I'm writing my own library for this instead of using a pre-existing one that would handle things like this
	# but we've already gotten this far...
	Database.instance.call("update meta set svalue = replace(svalue, ',', '_') where varname = 'upload_name'", echo=False)

def check_upload_history(check_valid=None, show_missing=False):
	
	present_mandatory = []
	missing_mandatory = []
	present_optional  = []
	missing_optional  = []
	valid_optional    = []

	uploads_hist = []
	with open(BINDIR + '/common_files/tin_upload_history.txt') as upload_hist:
		for i, line in enumerate(upload_hist):
			if i == 0:
				continue
			line = line.split('#')[0]
			if not line:
				continue
			uploads_hist.append(line.strip().split()[0])
	
	uploads_hist = list(reversed(uploads_hist))
	#logging.debug(uploads_hist)

	#clean_up_meta_table()
	database_uploads_hist = Database.instance.select("select svalue, ivalue from (select distinct on (svalue) svalue, ivalue from meta where varname = 'upload_name') t order by t.ivalue desc").all()

	while not len(uploads_hist) == 0 and not len(database_uploads_hist) == 0:
		db_upload = None

		db_upload = database_uploads_hist.pop()[0]
		upload = uploads_hist.pop()

		optional = False
		if upload.endswith('*'):
			upload = upload[:-1]
			optional = True
			while optional and db_upload != upload:
				missing_optional.append(upload)
				#logging.debug('opt* '+ upload)
				upload = uploads_hist.pop()
				optional = upload.endswith('*')
				if optional:
					upload = upload[:-1]
			if optional and db_upload == upload:
				present_optional.append(upload)

		#logging.debug('db_upload={}, upload={}, uploads_hist={}, db_uploads_hist={}, opt={}'.format(db_upload, upload, uploads_hist, database_uploads_hist, optional))

		if upload != db_upload and not optional:
			raise Exception("database history out of order! up: {}, dbu: {}".format(upload, db_upload))
		#if upload == check_valid:
		#	return True # indicates check_valid is valid & present in the history -

		present_mandatory.append(upload)

	#if len(uploads_hist) == 0:
	#	if len(database_uploads_hist) == 0 and not check_valid:
	#		pass
	#	elif len(database_uploads_hist) == 0:
	#		raise Exception('transaction {} does not exist in the history!'.format(check_valid))
	#	else:
	#		raise Exception("database has more transactions than are recorded in the history file!")
	if len(uploads_hist) > 0:
		remaining_mandatory = list(filter(lambda x:not x.endswith('*'), uploads_hist))
		missing_mandatory.extend(remaining_mandatory)
		if len(remaining_mandatory) > 0:
			oldest_mandatory = remaining_mandatory[-1]
			oldest_idx = uploads_hist.index(oldest_mandatory)
			optional_remaining = uploads_hist[oldest_idx+1:]
			valid_optional.extend([x[:-1] for x in optional_remaining])
		else:
			oldest_mandatory = oldest_idx = None
			optional_remaining = list(filter(lambda x:x.endswith('*'), uploads_hist))
			valid_optional.extend([x[:-1] for x in optional_remaining])
		# if the histories correspond up to this point, and there are more uploads to be done, then check that the set to be uploaded matches the oldest set not yet uploaded
		#if not check_valid or check_valid == oldest_mandatory or check_valid+'*' in optional_remaining:
		#	pass
		#else:
		#	raise Exception('transaction {} not valid for current database'.format(check_valid))

	#if show_missing:
	#	remaining_mandatory = list(filter(lambda x:not x.endswith('*'), uploads_hist))
	#	if len(remaining_mandatory) > 0:
	#		oldest_mandatory = remaining_mandatory[-1]
	#		oldest_idx = uploads_hist.index(oldest_mandatory)
	#		optional_remaining = uploads_hist[oldest_idx+1:]
	#	else:
	#		oldest_mandatory = oldest_idx = None
	#		optional_remaining = list(filter(lambda x:x.endswith('*'), uploads_hist))

	#	print("missing required={}, optional={}".format(','.join(remaining_mandatory), ','.join(optional_remaining)))

	#return True
	return present_mandatory, missing_mandatory, present_optional, missing_optional, valid_optional

def validate_history(check_valid=None, show_missing=False):
	present_mandatory, missing_mandatory, present_optional, missing_optional, valid_optional = check_upload_history()

	if check_valid:
		if check_valid in present_mandatory or check_valid == missing_mandatory[-1] or check_valid in valid_optional:
			return True
		else:
			raise Exception('{} not valid for database!'.format(check_valid))

	if show_missing:
		logging.debug('missing mandatory: {}'.format(missing_mandatory))
		logging.debug('missing optional: {}'.format(missing_optional))
		logging.debug('valid optional: {}'.format(valid_optional))
		if len(missing_mandatory) > 0:
			raise Exception('latest missing: {}'.format(missing_mandatory))

