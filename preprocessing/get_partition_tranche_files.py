import os
import sys

class Rangemap:

    def __init__(self, fn):

        with open(fn, 'r') as rangemap:
            self.rangevals = rangemap.read().split()

        self.map = {}
        self.invmap = {}
        for i, logp in enumerate(self.rangevals):
            self.map[logp] = i
            self.invmap[i] = logp

    def get(self, hlogp):
        h = int(hlogp[1:3])
        p = self.map[hlogp[3:]]
        return h, p

    def getinv(self, h, p):
        hlogp_str = "H{:>02d}{}".format(h, self.invmap[p])
        return hlogp_str

tranche_dir = sys.argv[1]
start, end = sys.argv[2], sys.argv[3]

basedir = os.path.dirname(__file__)

sys.stderr.write("{} {}".format(start, end))
rangemap = Rangemap(os.path.join(basedir, "mp_range.txt"))
start, end = rangemap.get(start), rangemap.get(end)

out = []

for tranche_subdir in os.listdir(tranche_dir):
    for tranche_file in os.listdir(os.path.join(tranche_dir, tranche_subdir)):
        hlogp = os.path.basename(tranche_file).split(".")[0]
        if hlogp == '' or hlogp[0] != 'H':
            continue
        try:
            pos = rangemap.get(hlogp)
        except Exception as err:
           pass
        if pos[0] <= end[0] and pos[0] >= start[0] and pos[1] <= end[1] and pos[1] >= start[1]:
            out.append(os.path.join(os.path.join(tranche_dir, tranche_subdir), tranche_file))

print(" ".join(out))
