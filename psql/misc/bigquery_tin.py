import psycopg2
import io

logp_buckets = ['M500', 'M400', 'M300', 'M200', 'M100', 'M000', 'P000', 'P010', 'P020', 'P030', 'P040', 'P050', 'P060', 'P070', 'P080', 'P090', 'P100', 'P110', 'P120', 'P130', 'P140', 'P150', 'P160', 'P170', 'P180', 'P190', 'P200', 'P210', 'P220', 'P230', 'P240', 'P250', 'P260', 'P270', 'P280', 'P290', 'P300', 'P310', 'P320', 'P330', 'P340', 'P350', 'P360', 'P370', 'P380', 'P390', 'P400', 'P410', 'P420', 'P430', 'P440', 'P450', 'P460', 'P470', 'P480', 'P490', 'P500', 'P600', 'P700', 'P800', 'P900']
logp_map = {p : i for i, p in enumerate(logp_buckets)}
base62_alphabet = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
base62_map = {c : i for i, c in enumerate(base62_alphabet)}

def base62_to_int(n):
    tot = pwr = 0
    for c in reversed(n):
        tot += 62**pwr * base62_map[c]
        pwr += 1
    return tot

def int_to_base62(n):
    b62_str=""
    while n >= 62:
        n, r = divmod(n, 62)
        b62_str += base62_alphabet[r]
    b62_str += base62_alphabet[n]
    return ''.join(reversed(b62_str))

def extract_zincid_info(zinc_id):
    hac = base62_to_int(zinc_id[4])
    logp = logp_buckets[base62_to_int(zinc_id[5])]
    sub_id = base62_to_int(zinc_id[6:])
    tranche = "H{:>02d}{}".format(hac, logp)
    return tranche, sub_id

def encode_zincid(sub_id, tranche):
    h_bucket = int(tranche[1:3])
    logp_bucket = logp_map[tranche]
    b62_h = int_to_base62(h_bucket)
    b62_p = int_to_base62(logp_bucket)
    b62_sub = int_to_base62(sub_id)
    b62_sub = (10 - len(b62_sub)) * "0" + b62_sub
    return "ZINC" + b62_h + b62_p + b62_sub

# main function for doing a big query
# takes in a list of zinc ids (string), outputs a list of smiles + zinc ids (string, string)
def big_zincid_query(zinc_ids, dsn):

    conn = psycopg2.connect(dsn)
    curs = conn.cursor()
    #meta = MetaData(bind=conn)

    # this is our input table- what we are querying
    curs.execute("create temporary table temp_query_a(sub_id int, tranche_id smallint)")

    # this is our output table, what we want in our results
    curs.execute(
        "CREATE TEMPORARY TABLE temp_query_b (\
            sub_id_fk int,\
            cat_content_id_fk int,\
            smiles text,\
            code text,\
            tranche_id smallint)")

    # now we want to know the actual tranche each tranche_id maps to in this database, do this by retrieving the tranches table
    # this information could conceivably be saved somewhere more convenient than the remote database, since it is not subject to change
    # searching with tranche information specified in addition to sub_id should speed up our query significantly
    curs.execute("select tranche_name, tranche_id from tranches")
    trancheidmap = {}
    tranchenamemap = {}
    for trancheobj in curs.fetchall():
        tranchename = trancheobj[0]
        trancheid = trancheobj[1]
        trancheidmap[tranchename] = trancheid
        tranchenamemap[trancheid] = tranchename

    # we want to write all the data we want to query to a file object, so that we can use copy_from() to load data into our temporary table
    # creating a table allows us to perform a join operation between the substance table and our query, this is more efficient for large queries (as opposed to using in_() with literal values)
    big_query_string = ""
    for zinc_id in zinc_ids:
        tranche, sub_id = extract_zincid_info(zinc_id)
        try:
            tranche_id = trancheidmap[tranche]
        except:
            print("tranche for {} does not exist in this database!".format(zinc_id))
            continue
        big_query_string += "{},{}\n".format(sub_id, tranche_id) # make our data comma separated
    big_query_fileobj = io.StringIO(big_query_string)

    # this is where we need the raw connection- copy_from (https://www.psycopg.org/docs/cursor.html#cursor.copy_from)
    curs.copy_from(big_query_fileobj, 'temp_query_a', sep=',', columns=('sub_id', 'tranche_id'))

    curs.execute(
        "INSERT INTO temp_query_b (\
            sub_id_fk,\
            cat_content_fk,\
            tranche_id) (\
            SELECT\
                cs.sub_id_fk,\
                cs.cat_content_fk,\
                cs.tranche_id\
            FROM\
                catalog_substance cs,\
                temp_query_a q\
            WHERE\
                cs.sub_id_fk = q.sub_id\
                AND cs.tranche_id = q.tranche_id)")

    curs.execute(
        "SELECT\
            temp_query_b.sub_id_fk,\
            temp_query_b.cat_content_fk,\
            temp_query_b.tranche_id,\
            substance.smiles,\
            catalog_content.supplier_code\
         FROM\
            temp_query_b\
            INNER JOIN substance ON temp_query_b.sub_id_fk = substance.sub_id\
            INNER JOIN catalog_content ON catalog_content.cat_content_id = temp_query_b.cat_content_fk")
    # old inefficient method
"""
    curs.execute(
        "UPDATE\
            temp_query_b q\
        SET\
            q.smiles = sb.smiles\
        FROM\
            substance sb\
        WHERE\
            sb.sub_id = q.sub_id_fk\
            AND sb.tranche_id = q.tranche_id")

    curs.execute(
        "UPDATE\
            temp_query_b q\
        SET\
            q.code = cc.supplier_code\
        FROM\
            catalog_content cc\
        WHERE\
            cc.cat_content_id = q.cat_content_fk\
            AND cc.tranche_id = q.tranche_id")
"""

    results = []
    for result in curs.fetchall():

        #data = result.json()  
        smiles = result[3]
        scode  = result[4]
        sub_id = result[0]
        tranche = tranchenamemap[result[2]]
        # get zinc id back from sub_id + tranche and append to results with smiles
        zincid = encode_zincid(sub_id, tranche)
        results.append((zincid, smiles, scode))

    conn.rollback()
    conn.close()

    return results

# much the same as the big zinc_id query, basically its inverse
def big_code_query(supplier_codes, dsn):

    conn = psycopg2.connect(dsn)
    curs = conn.cursor()

    # input table
    curs.execute("create temporary table temp_query_a(supplier_code text)")

    # output table
    curs.execute(
        "CREATE TEMPORARY TABLE temp_query_b (\
            sub_id_fk int,\
            cat_content_id_fk int,\
            smiles text,\
            code text,\
            tranche_id smallint)")

    curs.execute("select tranche_name, tranche_id from tranches")
    trancheidmap = {}
    tranchenamemap = {}
    for trancheobj in curs.fetchall():
        tranchename = trancheobj[0]
        trancheid = trancheobj[1]
        trancheidmap[tranchename] = trancheid
        tranchenamemap[trancheid] = tranchename

    big_query_string = "\n".join(supplier_codes)
    big_query_fileobj = io.StringIO(big_query_string)

    curs.copy_from(big_query_fileobj, 'temp_query_a')

    curs.execute(
        "INSERT INTO temp_query_b (\
            cat_content_id_fk,\
            code,\
            tranche_id) (\
            SELECT\
                cc.cat_content_id,\
                cc.supplier_code,\
                cc.tranche_id\
            FROM\
                catalog_content cc,\
                temp_query_a q\
            WHERE\
                cc.supplier_code = q.supplier_code)")

    curs.execute(
        "UPDATE\
            temp_query_b q\
        SET\
            q.sub_id_fk = cs.sub_id_fk\
        FROM\
            catalog_substance cs\
        WHERE\
            cs.cat_content_fk = q.cat_content_id_fk\
            AND sb.tranche_id = q.tranche_id")

    curs.execute(
        "UPDATE\
            temp_query_b q\
        SET\
            q.smiles = sb.smiles\
        FROM\
            substance sb\
        WHERE\
            sb.sub_id = q.sub_id_fk\
            AND sb.tranche_id = q.tranche_id")

    results = []
    curs.execute("select * from temp_query_b")
    for result in curs.fetchall():

        smiles = result[2]
        scode  = result[3]
        sub_id = result[0]
        tranche = tranchenamemap[result[4]]

        # get zinc id back from sub_id + tranche and append to results with smiles
        zincid = encode_zincid(sub_id, tranche)
        results.append((zincid, smiles, scode))

    conn.rollback()
    conn.close()

    return results

if __name__ == "__main__":
    dsn = sys.argv[1]
    zincids_file = sys.argv[2]
