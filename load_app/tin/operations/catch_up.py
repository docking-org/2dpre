# uploads every mandatory catalog in the history in order
import logging
from load_app.tin.upload_hist import check_upload_history,validate_history
from load_app.tin.operations.upload import emulate_upload
from load_app.tin.operations.upload_zincid import upload_zincid
from load_app.common.consts import *
from load_app.common.database import Database
import logging
#open env

import psycopg2
import psycopg2
def database_catch_up(args):
    present_mandatory, missing_mandatory, present_optional, missing_optional, valid_optional, id_to_optype = check_upload_history()
    to_upload = missing_mandatory

    uploads_hist = []
    conn = psycopg2.connect(CONFIG_DB_URL)
    cur = conn.cursor()

    cur.execute('select machine_id from tin_machines where hostname = %s and port = %s', (Database.instance.host, Database.instance.port))
    machine_id = cur.fetchone()[0]
    #select from tin_upload_history where machines array contains machine_id

    cur.execute("select * from tin_upload_history where machines @> ARRAY[%s]::int[] and optype='upload' or optype='upload_zincid' order by u_order asc", (machine_id,))

    h = cur.fetchall()
    
    for line in h:
        transaction_id, optype, optional,source,diffdest = line[0:5]
        uploads_hist.append({
            'transaction_id': transaction_id,
            'optype': optype,
            'optional': optional,
            'source':source,
            'diffdest':diffdest
        })
    print("these will be uploaded in order:", missing_mandatory)
    if len(missing_mandatory) == 0:
        print("nothing to upload!")
        return
    for i in missing_mandatory:
        print(i)
        transaction = [x for x in uploads_hist if x['transaction_id'] == i][0]
        if transaction['optype'] == 'upload' or transaction['optype'] == 'upload_zincid':
            args.catalogs = i
            args.cat_shortnames = i
            args.source_dirs = transaction['source']
            args.diff_destination = transaction['diffdest']
            args.transaction_id = i
            
            
            if validate_history(i):
                print("uploading", i)
                if transaction['optype'] == 'upload':
                    emulate_upload(args)
                elif transaction['optype'] == 'upload_zincid':
                    
                    args.source_dirs = [transaction['source']]
                    args.generate_source = False
                    upload_zincid(args)
                
            else:
                raise Exception("Database not valid. Check the upload order.")
        