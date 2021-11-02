COPY (select smiles, sub_id, tranche_name from substance left join tranches on substance.tranche_id = tranches.tranche_id) to STDOUT;
