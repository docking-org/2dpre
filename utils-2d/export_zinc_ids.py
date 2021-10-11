import sys
import os

BINDIR = os.path.dirname(sys.argv[0]) or '.'

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

def base62(n):
    digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    b62_str=""
    while n >= 62:
        n, r = divmod(n, 62)
        b62_str += digits[r]
    b62_str += digits[n]
    return ''.join(reversed(b62_str))

def base62_rev(n):
    digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    tot = 0
    for i, d in enumerate(reversed(n)):
        tot += digits.index(d) * 62**i
    return tot

digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
digits_map = {d:i for i, d in enumerate(digits)}
def base62_rev_zincid(n):
    tot = 0
    # manually unrolling this loop to optimize for decoding zinc ids
    tot += digits_map[n[9]]
    tot += digits_map[n[8]] * 62
    tot += digits_map[n[7]] * 3844
    tot += digits_map[n[6]] * 238328
    tot += digits_map[n[5]] * 14776336
    tot += digits_map[n[4]] * 916132832
    tot += digits_map[n[3]] * 56800235584
    tot += digits_map[n[2]] * 3521614606208
    tot += digits_map[n[1]] * 218340105584896
    tot += digits_map[n[0]] * 13537086546263552
    #for i, d in enumerate(reversed(n)):
    #    tot += digits_map[d] * 62**i
    return tot

def get_info_zincid(zincid):
    rangemap = Rangemap(BINDIR + "/mp_range.txt")
    sub_id = base62_rev(zincid[6:])
    hac = base62_rev(zincid[4])
    logp = base62_rev(zincid[5])
    tranche = rangemap.getinv(hac, logp)
    return tranche, sub_id

def export_to_file(infile, outfilehandle, tranche, binpath):

    rangemap=Rangemap(binpath + "/mp_range.txt")
    h_bucket, logp_bucket = rangemap.get(tranche)

    with open(infile, 'r') as smiles_file:

        for line in smiles_file:

            smiles, tranche, sub_id = line.split()

            #h_bucket, logp_bucket = rangemap.get(tranche)

            b62_h = base62(h_bucket)
            b62_p = base62(logp_bucket)
            b62_sub = base62(int(sub_id))

            b62_sub = (10 - len(b62_sub)) * "0" + b62_sub

            zinc_id = "ZINC" + b62_h + b62_p + b62_sub

            assert(len(zinc_id) == 16)

            outfilehandle.write("{} {}\n".format(smiles, zinc_id))
