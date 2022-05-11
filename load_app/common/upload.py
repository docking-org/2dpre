from load_app.common.consts import *
from load_app.common.database import Database

# should move these functions to an "upload_common" file for organizational purposes
# for now they are like this
def make_hash_partitions(table_name, N):

    for i in range(N):
        code = Database.instance.call("create table {0}_p{1} partition of {0} for values with (modulus {2}, remainder {1})".format(table_name, i, N))
        if code != 0:
            raise NameError("failed to create hash partitions for {}:{}:{}".format(Database.instance.port, table_name, N))
            return False
    return True

def get_partitions_count(database_port):
    n_partitions = int(call_psql(cmd="select ivalue from meta where svalue = 'n_partitions' limit 1", getdata=True)[1][0])
    return n_partitions

def create_transaction_record_table(transaction_identifier):

    code  = Database.instance.call("create table if not exists transaction_record_{} (stagei int, parti int, nupload int, nnew int)".format(transaction_identifier))
    code |= Database.instance.call("insert into transaction_record_{} (values (-1, -1, 0, 0))".format(transaction_identifier))

    if code == 0:
        return True
    return False

def check_transaction_record(transaction_identifier, stagei, parti):

    data = Database.instance.select("select * from transaction_record_{} where parti = {} and stagei = {}".format(transaction_identifier, parti, stagei))

    if not data.empty():
        return True
    return False

def check_transaction_started(transaction_identifier):
    return check_transaction_record(transaction_identifier, -1, -1)

#############

def upload_complete(port, transaction_id):
    data = Database.instance.select("select svalue from meta where svalue = '{}'".format(transaction_id))
    if not data.empty():
        return True
    else:
        return False

def increment_version(db_port, uploadname):
    Database.instance.call("update meta set ivalue = ivalue + 1 where varname = 'version'")
    version_no = get_version()
    Database.instance.call("insert into meta(varname, svalue, ivalue) (values ('upload_name', '{}', {}))".format(uploadname, version_no))

def get_version():
    data = Database.instance.select("select ivalue from meta where varname = 'version'").first().ivalue
    return int(data)