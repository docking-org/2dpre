copy (select supplier_code, right(sha256(supplier_code::bytea)::varchar, 4) last4hash, cat_content_id from catalog_content order by last4hash) to :'output_file';
