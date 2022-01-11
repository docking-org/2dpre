import sys, os
digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
logp_range="M500 M400 M300 M200 M100 M000 P000 P010 P020 P030 P040 P050 P060 P070 P080 P090 P100 P110 P120 P130 P140 P150 P160 P170 P180 P190 P200 P210 P220 P230 P240 P250 P260 P270 P280 P290 P300 P310 P320 P330 P340 P350 P360 P370 P380 P390 P400 P410 P420 P430 P440 P450 P460 P470 P480 P490 P500 P600 P700 P800 P900".split(" ")
if len(sys.argv) > 1:
	output = sys.argv[1]
else:
	output = "/tmp"
if len(sys.argv) > 2:
	targetcolumn = int(sys.argv[2])
else:
	targetcolumn = 1
with open(0) as readin:

	currtranche = None
	currtranchefile = None

	for line in readin:
		zincid = line.strip().split()[targetcolumn-1]
		if len(zincid) != 16:
			continue
		tranche = zincid[4:6]
		if tranche != currtranche:
			currtranche = tranche
			if currtranchefile:
				currtranchefile.close()
			h_ind = digits.index(tranche[0])
			p_ind = digits.index(tranche[1])
			tranchename = "H{:02d}{}".format(h_ind, logp_range[p_ind])
			currtranchefile = open(output + "/{}.txt".format(tranchename), 'w')
		currtranchefile.write(line)

	currtranchefile.close()
