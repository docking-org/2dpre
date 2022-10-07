from rdkit import Chem
import sys
from rdkit import RDLogger

# get rid of rdkit warning messages gumming things up
RDLogger.DisableLog('rdApp.*')

canon=sys.argv[1]
noncanon=sys.argv[2]

def neutralize_atoms(mol):
    pattern = Chem.MolFromSmarts("[+1!h0!$([*]~[-1,-2,-3,-4]),-1!$([*]~[+1,+2,+3,+4])]")
    at_matches = mol.GetSubstructMatches(pattern)
    at_matches_list = [y[0] for y in at_matches]
    if len(at_matches_list) > 0:
        for at_idx in at_matches_list:
            atom = mol.GetAtomWithIdx(at_idx)
            chg = atom.GetFormalCharge()
            hcount = atom.GetTotalNumHs()
            atom.SetFormalCharge(0)
            atom.SetNumExplicitHs(hcount - chg)
            atom.UpdatePropertyCache()
    return mol

# unfortunately, the way we canonicalize molecules is to convert smiles->mol->inchi and then inchi->mol->smiles
# technically, we could get away with smiles->mol->smiles, but then again maybe not. I don't know chemistry too well

canon_f = open(canon, 'w')
noncanon_f = open(noncanon, 'w')

for line in sys.stdin:

	tokens = line.strip().split()
	smiles = tokens[0]
	identity = tokens[1]
	# some smiles have a bit added to the end that looks like: ^|1:13| separated by a space
	# in order to make my life easier I substitute all spaces for underscores at export time (since space is the column delimiter we use in our flat files)
	# need to put the space back here so rdkit can parse it
	# technically, these shouldn't even be in the database. they probably won't be for much longer
	smiles = ' '.join(smiles.split('_'))
	m = Chem.MolFromSmiles(smiles)
	try:
		m = neutralize_atoms(m)
	except Exception as e:
		print("problematic mol:", smiles, identity, ' '.join(str(e).split('\n')))
		noncanon_f.write('{} {} {}\n'.format(smiles, "NONE", identity))
		continue
	inchi = Chem.inchi.MolToInchi(m, options='/RecMet')
	std_m = Chem.inchi.MolFromInchi(inchi)
	try:
		smiles_canon = Chem.MolToSmiles(std_m)
	except Exception as e:
		print("problematic mol:", smiles, identity, ' '.join(str(e).split('\n')))
		noncanon_f.write('{} {} {}\n'.format(smiles, "NONE", identity))
		continue
	#smiles = '_'.join(smiles.split(' ')) # put the underscores back
	#smiles_canon = '_'.join(smiles.split(' '))
	if smiles != smiles_canon:
		noncanon_f.write('{} {} {}\n'.format(smiles, smiles_canon, identity))
	else:
		canon_f.write('{} {}\n'.format(smiles, identity))
