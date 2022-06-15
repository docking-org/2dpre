from export_zinc_ids import get_info_zincid
import sys, subprocess, os

infn = sys.argv[1]

legacy_targets = [
"/nfs/exb/zinc22/export/deprecated/ZINC_21Q2",
"/nfs/exb/zinc22/export/deprecated/2d-09",
"/nfs/exb/zinc22/export/deprecated/2d-10",
"/nfs/exb/zinc22/export/deprecated/2d-01",
"/nfs/exb/zinc22/export/deprecated/2d-11",
"/nfs/exb/zinc22/export/deprecated/2d-12-diff/2d/finished"]
curr_buffer = []
curr_hac = None
curr_tranche = None

outbuffer = open('result', 'w')

def check_targets(curr_buffer, outbuffer, tranche, hac):
	for target in legacy_targets:
		print(target, curr_tranche, curr_buffer)
		if len(curr_buffer) == 0:
			break
		tfile = os.path.join(target, curr_hac, curr_tranche)
		if os.path.exists(tfile + '.smi'):
			tfile = tfile + '.smi'
			g = "grep"
		elif os.path.exists(tfile + '.smi.gz'):
			tfile = tfile + '.smi.gz'
			g = "zgrep"
		else:
			continue
		with subprocess.Popen([g, "-E", '|'.join(curr_buffer), tfile], stdout=subprocess.PIPE) as spt:
			for line in spt.stdout:
				f1, f2 = line.decode('utf-8').strip().split()
				if f1.startswith("ZINC"):
					zincid = f1
					smiles = f2
				else:
					zincid = f2
					smiles = f1
				print(zincid, smiles)
				outbuffer.write('\t'.join([zincid, smiles]) + '\n')
				#outbuffer.append('\t'.join([zincid, smiles]))
				try: # if there's a duplicate there may be an error in this .remove statement
					curr_buffer.remove(zincid)
				except:
					pass

with open(infn, 'r') as inf:
	lines = sorted([l.strip() for l in inf.readlines()])
	print(lines[0:10])
	for line in lines:
		print(line)
		tranche, sub_id = get_info_zincid(line)
		hac = tranche[:3]
		if tranche != curr_tranche:
			check_targets(curr_buffer, outbuffer, curr_tranche, curr_hac)
			if len(curr_buffer) != 0:
				print("unable to find: {}".format(curr_buffer))
			curr_tranche = tranche
			curr_hac = hac
			curr_buffer = [line]
		else:
			curr_buffer.append(line)
check_targets(curr_buffer, outbuffer, curr_tranche, curr_hac)

outbuffer.close()
#with open("result", 'w') as resf:
#	for res in outbuffer:
#		resf.write(res + '\n')
