from export_zinc_ids import zincid_to_subid_opt
import sys

if __name__ == "__main__":
    infile = sys.argv[1]
    outfile = sys.argv[2]
    tranche_id = int(sys.argv[3])
    zincid_pos = int(sys.argv[4])
    if infile == "-":
        infile = 0
    if outfile == "-":
        outfile = 1
    zincid_to_subid_opt(infile, outfile, tranche_id, zincid_pos)
