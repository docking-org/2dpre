from load_app.tin.common import get_tranches, zincid_to_subid_opt, get_tranche_id, call_psql, BINDIR, set_patched
import os, sys, subprocess

def patch_database_fix12(port):

	tranches = get_tranches(port)

	noncanon_dir = '/nfs/exb/zinc22/2d-12-noncanon'
	# missing refers to moleules in 2d01-08 but not detected in the 2d-12 export
	# this could be for a number of reasons- some molecules simply failed to be exported to 2d-12, notably strange radical molecules, for whatever reason
	# some molecules in 2d-12 are missing their backslashes for some reason compared to 2d01-08
	# and some molecules are just entirely wrong- e.g have a completely different zincid:smiles
	# that last category seems to be restricted to H29 tranches, but that is not 100%. sorta the purpose of this patch, to find out (as well as fix the databases)
	missing_sub_dir = '/nfs/exb/zinc22/2d-12-diff/2d/staging'
	corrections_dir = '/nfs/exb/zinc22/2d-12-diff/2d/corrections/{}_{}'.format(tranches[0], tranches[-1])
	stage_dir = '/local2/load/fix12_{}'.format(port)

	os.system("mkdir -p {}".format(corrections_dir))
	os.system("chmod 777 {}".format(corrections_dir))
	os.system("mkdir -p {}".format(stage_dir))

	to_concat_noncanon = []
	to_concat_missing = []
	tranches_new_nc = []
	tranches_new_ms = []
	for tranche in tranches:
		hac = tranche[0:3]

		noncanon_f = "{}/{}/{}.smi".format(noncanon_dir, hac, tranche)
		if not os.path.exists(noncanon_f):
			print("couldn't find noncanon file for {}!".format(tranche))
		else:
			to_concat_noncanon.append(noncanon_f)
			tranches_new_nc.append(tranche)

		missing_f = "{}/{}/{}/diff.src".format(missing_sub_dir, hac, tranche)
		if not os.path.exists(missing_f):
			print("couldn't find missing file for {}!".format(tranche))
		else:
			to_concat_missing.append(missing_f)
			tranches_new_ms.append(tranche)

	to_cat = []
	for tranche, nc_file in zip(tranches_new_nc, to_concat_noncanon):
		tranche_id = get_tranche_id(port, tranche)
		zincid_idx = 3
		with open(nc_file, 'r') as ncf:
			tokens = ncf.readline().strip().split()
			if tokens: zincid_idx = [1 if t.startswith("ZINC") else 0 for t in tokens].index(1) + 1
		zincid_to_subid_opt(nc_file, stage_dir + '/' + tranche + '.nc', tranche_id, zincid_idx, only_output_zincid=True)
		to_cat.append(stage_dir + '/' + tranche + '.nc')
	noncanon_staged_file = stage_dir + "/all.nc"
	if os.path.exists(noncanon_staged_file):
		os.remove(noncanon_staged_file)
	ncf = open(noncanon_staged_file, 'w')
	p1 = subprocess.Popen(["cat"] + to_cat, stdout=ncf)

	to_cat = []
	for tranche, ms_file in zip(tranches_new_ms, to_concat_missing):
		tranche_id = get_tranche_id(port, tranche)
		zincid_to_subid_opt(ms_file, stage_dir + '/' + tranche + '.ms', tranche_id, 1)
		to_cat.append(stage_dir + '/' + tranche + '.ms')
	missing_staged_file = stage_dir + "/all.ms"
	if os.path.exists(missing_staged_file):
		os.remove(missing_staged_file)
	msf = open(missing_staged_file, 'w')
	# escape characters need to be added in to the "missing" smiles
	p3 = subprocess.Popen(["sed", "s/\\\\/\\\\\\\\/g"], stdout=msf)
	p2 = subprocess.Popen(["cat"] + to_cat, stdout=p3.stdin)

	p1.wait()
	p2.wait()
	p3.wait()

	ncf.close()
	msf.close()

	psql_vars = {
			"noncanon_src_f" : noncanon_staged_file,
			"escaped_src_f" : missing_staged_file,
			"mismatch_file" : corrections_dir + "/mismatch",
			"missing_file" : corrections_dir + "/missing",
			"mystery_file" : corrections_dir + "/mystery"
	}
	print(psql_vars)

	code = call_psql(port, vars=psql_vars, psqlfile=BINDIR + '/psql/tin_fix_2d12.pgsql')

	success = False
	if code == 0:
		set_patched(port, "fix12", True)
		success = True
	return success

