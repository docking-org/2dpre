copy (select smiles, sub_id, tranche_name from substance sb join tranches t on sb.tranche_id = t.tranche_id) to :'output_file';
