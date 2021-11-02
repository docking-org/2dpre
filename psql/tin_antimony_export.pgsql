copy (select supplier_code, right(sha256(supplier_code), 4) last4hash, :machine_id, cat_content_id from catalog_content order by last4hash) to :'output_file';
