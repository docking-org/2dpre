import os, sys
import argparse

parser = argparse.ArgumentParser(description="encode raw tin exports to zinc ids")
parser.add_argument("source", type=str)
parser.add_argument("target", type=str)
args = parser.parse_args()

if not args.source == '-' and not os.path.isfile(args.source):
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

if args.source == '-':
	sourcefile = sys.stdin
else:
	sourcefile = open(args.source, 'r')

with open(args.target, 'w') as targetfile:

	with sourcefile:

		for line in sourcefile:

			tokens = line.strip().split()
			smiles, subid, tranche = tokens[0], tokens[1], tokens[2]
			b62_subid = base62(int(subid))
			b62_h = base62(int(tranche[1:3]))
			b62_p = base62(logp_range[tranche[3:]])
			b62_subid = "0" * (10 - len(b62_subid)) + b62_subid
			zincid = "ZINC" + b62_h + b62_p + b62_subid
			assert(len(zincid) == 16)
			targetfile.write(" ".join([smiles, zincid] + tokens[3:]) + "\n")
