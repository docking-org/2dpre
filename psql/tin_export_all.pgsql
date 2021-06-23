COPY (
    SELECT
        sb.smiles,
        sb.sub_id,
        cc.cat_id_fk
    FROM
        substance sb,
        catalog_substance cs,
        catalog_content cc
    WHERE
        sb.sub_id = cs.sub_id_fk
        AND cc.cat_content_id = cs.cat_content_fk
        AND sb.tranche_id = cs.tranche_id
        AND cc.tranche_id = cs.tranche_id)
TO STDOUT;

