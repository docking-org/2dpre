begin;

	delete from meta where varname in ('version', 'upload_name');
	copy meta from :'hist' delimiter ',';

commit;
