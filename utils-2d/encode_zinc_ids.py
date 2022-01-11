import os, sys
import argparse

parser = argparse.ArgumentParser(description="encode raw tin exports to zinc ids")
parser.add_argument("source", type=str)
parser.add_argument("target", type=str)
args = parser.parse_args()

if not os.path.isfile(args.source):
	print("source is not a file!")
	sys.exit(1)

digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
logp_range="M500 M400 M300 M200 M100 M000 P000 P010 P020 P030 P040 P050 P060 P070 P080 P090 P100 P110 P120 P130 P140 P150 P160 P170 P180 P190 P200 P210 P220 P230 P240 P250 P260 P270 P280 P290 P300 P310 P320 P330 P340 P350 P360 P370 P380 P390 P400 P410 P420 P430 P440 P450 P460 P470 P480 P490 P500 P600 P700 P800 P900".split(" ")
logp_range={e:i for i, e in enumerate(logp_range)}

def base62(n):
    b62_str=""
    while n >= 62:
        n, r = divmod(n, 62)
        b62_str += digits[r]
    b62_str += digits[n]
    return ''.join(reversed(b62_str))

with open(args.target, 'w') as targetfile:

	with open(args.source, 'r') as sourcefile:

		for line in sourcefile:

			tokens = line.strip().split()
			if len(tokens) == 4: # this bit is for extended SMILES, which leave a space gap between the smiles string and a little bracketed bit (e.g CCC1C |1^1|)
				smiles = tokens[0] + "_" + tokens[1] # join with an underscore, which I don't like, but will cause the least problems down the line (i think)
				subid = tokens[2]
				tranche = tokens[3]
			else:
				smiles, subid, tranche = tokens[0], tokens[1], tokens[2]
			b62_subid = base62(int(subid))
			b62_h = base62(int(tranche[1:3]))
			b62_p = base62(logp_range[tranche[3:]])
			b62_subid = "0" * (10 - len(b62_subid)) + b62_subid
			zincid = "ZINC" + b62_h + b62_p + b62_subid
			assert(len(zincid) == 16)
			targetfile.write(" ".join([smiles, zincid]) + "\n")
