import sys, os
# estimate the number of lines in a file by sampling a portion of them
def estimate_lines(target_file, sample_lines=1000):
	with open(target_file, 'r') as est_file:
		vals = []
		for i in range(sample_lines):
			l = est_file.readline()
			if not l:
				break
			ll = len(l)
			vals.append(ll)
		if len(vals) == 0:
			return 0
		avg = sum(vals)/len(vals)
		tot_size = os.stat(target_file).st_size
		est_lines = int(tot_size/avg)
		return est_lines

import argparse
if __name__ == "__main__":
	ap = argparse.ArgumentParser()
	ap.add_argument('files', nargs='*')
	ap.add_argument('--files-from', type=str, default=None)
	ap.add_argument('--sample-lines', type=int, default=1000)
	args = ap.parse_args()

	for f in args.files:
		print(f, estimate_lines(f, sample_lines=args.sample_lines))
	if args.files_from:
		with open(args.files_from, 'r') as ff:
			for f in ff:
				f = f.strip()
				print(f, estimate_lines(f, sample_lines=args.sample_lines))
