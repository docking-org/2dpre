create temporary table oldsmiles(smiles text);
-- not sure why i need to set pstdin here
-- but if i just set "stdin" for some reason it treats the script file as the standard input instead of, yknow, actual standard input
-- aaand then the script terminates because the rest of it has just been copied in. fun stuff
\copy oldsmiles from pstdin;
copy (select sb.smiles, sb.sub_id, tr.tranche_name from oldsmiles os join substance sb on os.smiles = sb.smiles join tranches tr on tr.tranche_id = sb.tranche_id) to STDOUT;
