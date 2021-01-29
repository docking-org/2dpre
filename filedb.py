import sys
import argparse
import subprocess
import os

parser = argparse.ArgumentParser(prog="filedb.py", description='create or append data to a unique database file')

parser.add_argument('old', metavar="OLD", type=str, help='the existing database file. if the database does not exist yet, put the desired name for it here')
parser.add_argument('new', metavar="NEW", type=str, help='the column data to be added, should not have a primary key assigned yet')
parser.add_argument('--columns', dest='columns', type=str, help='the range of columns that should be unique\nex: --columns=1-3,5-6. defaults to all columns')
parser.add_argument('--resolve', dest='resolve', action='store_true', help='print the resolved primary keys of the column data to stdout')
parser.add_argument('--dest', dest='dest', type=str, help="file to append new entries to. By default this is the existing database file")
parser.add_argument('--length', type=int, dest='length', default=None, help='size of the existing database, by default the size of the existing database file. Use if striping a table over multiple files.')
parser.add_argument('--id-column', dest='idcolumn', type=int, default=0, help='the column of the primary key in the existing database')
parser.add_argument('--get-old', dest='get_old', action='store_true', help='write out existing entries to a .old file')

def get_num_lines(filename):
    with open(filename) as f:
        length = sum(1 for line in f)
    return length

def get_num_fields(filename):
    with subprocess.Popen(["head", "-n", "1", filename], stdout=subprocess.PIPE) as head_proc:
        with subprocess.Popen(["awk", "{print NF}", "-"], stdin=head_proc.stdout, stdout=subprocess.PIPE) as awk_proc:
            out = awk_proc.stdout.read().decode('utf-8')
            return int(out) if out else 0

# get an explicit list of column numbers from the columns argument string
def get_explicit_columns(column_args):
    all_columns = []
    for c_range in column_args.split(','):
        if '-' in c_range:
            start, end = (int(c) for c in c_range.split('-'))
            all_columns.extend([i for i in range(start, end+1)])
        else:
            all_columns.append(int(c_range))
    return sorted(all_columns)

def get_sort_key_args(column_args, idcolumn):
    sort_args = []
    id = False
    for c_range in column_args.split(','):
        if '-' in c_range:
            start, end = (int(c) for c in c_range.split('-'))        
        else:
            start, end = int(c_range), int(c_range)
        if start > idcolumn:
            sort_args.append("-k{0},{0}n".format(idcolumn, idcolumn))
            id = True
        sort_args.append("-k{0},{0}i".format(start, end))
    if not id:
        sort_args.append("-k{0},{0}n".format(idcolumn, idcolumn))
    return sort_args

def get_awk_command(ncolumns, idcolumn, old_length):
    cmd = "{print "
    id = False if idcolumn != 0 else True
    for column in range(1, ncolumns+1):
        if column == idcolumn:
            cmd += "{}+NR \" \"".format(old_length)
            id = True
            continue
        if id and idcolumn != 0:
            column -= 1
        cmd += "${} \" \"".format(column)
    if not id or idcolumn == 0:
        cmd += "{}+NR ".format(old_length)
    return cmd + "}"

def hidden_name(path):
    bd = os.path.dirname(path) or '.'
    bn = os.path.basename(path)
    return bd + '/' + '.' + bn

def append_file(source, dest, chunksize=1024*1024):
    chunk = source.read(chunksize)
    while chunk:
        dest.write(chunk)
        chunk = source.read(chunksize)

def main(args):

    old_fn = args.old
    new_fn = args.new
    # warm up the destination in case of empty input file
    with open(args.dest, 'a'):
        pass

    new_entries_fn = hidden_name(old_fn) + '.new'
    new_entries_f = open(new_entries_fn, 'w+')
    resolved_entries_fn = hidden_name(old_fn) + '.resolve'
    resolved_entries_f = None if not args.resolve else open(resolved_entries_fn, 'w')
    if args.get_old:
        old_entries_fn = old_fn + '.old'
        old_entries_f = open(old_entries_fn, 'w')

    try:

        # create a size zero file for the database if it doesn't exist yet so sort doesn't get confused
        if not os.path.isfile(old_fn):
            with open(old_fn, 'w') as database_f:
                pass

        len_old = args.length or get_num_lines(old_fn)
        old_fields = get_num_fields(old_fn)
        new_fields = get_num_fields(new_fn)
        # default to using all columns (apart from PK) as a sorting key if none are specified
        column_args = '1-' + str(new_fields) if not args.columns else args.columns
        all_columns = get_explicit_columns(column_args)
        if new_fields == 0:
            sys.stderr.write("0 new entries found\n")
            return
        assert((new_fields == (old_fields - 1)) or old_fields == 0)
        if old_fields == 0: # in the case of an empty database we set it's no. fields manually
            old_fields = new_fields + 1

        idcolumn = old_fields if not args.idcolumn else args.idcolumn
        cmd = get_awk_command(old_fields, args.idcolumn, len_old)
        
        with subprocess.Popen(["awk", cmd, new_fn], stdout=subprocess.PIPE) as proc_new_marker:
            # sort primarily by the selected column contents and secondarily by the primary key in the last column
            # since we've appended len_old+NR as the primary key of each new column entry, all duplicates from the new entries will be sorted *below* the original entries
            # this provisional key will also be important later during resolution (if the option is selected)
            sort_key_args = get_sort_key_args(column_args, idcolumn)
            with subprocess.Popen(["sort"] + sort_key_args + [old_fn, '-'], stdin=proc_new_marker.stdout, stdout=subprocess.PIPE) as proc_sorted:

                prev = None, None
                curr_new = 0

                for line in proc_sorted.stdout:

                    tokens = line.decode('utf-8').rstrip().split(" ")
                    idcolumn = old_fields if not args.idcolumn else args.idcolumn
                    column, idno = (' '.join([tokens[c-1] for c in all_columns]), int(tokens[idcolumn-1]))
                    column_left = ' '.join(tokens[:idcolumn-1])
                    column_right = ' '.join(tokens[idcolumn:])
                    #full_column = ' '.join(tokens[:idcolumn-1]+tokens[idcolumn:])

                    column_prev, idno_prev = prev

                    # here is the part where we find new entries
                    if not column_prev == column:
                        # if we find a non-duplicate column that belongs to the input list, we write it out to the new list
                        if idno > len_old:
                            new_entries_f.write(column_left + ' ' + str(len_old + curr_new + 1) + ' ' + column_right + '\n')
                            if args.resolve:
                                # we will also write it to our "resolved" list
                                resolved_entries_f.write(str(idno) + ' ' + str(len_old + curr_new + 1) + '\n')
                            curr_new += 1
                        prev = column, idno

                    else:
                        if idno <= len_old:
                            sys.stderr.write("PREV: {} {}".format(column_prev, idno_prev))
                            sys.stderr.write("CURR: {} {}".format(column, idno))
                            raise NameError("Something has gone terribly wrong. The existing database is not unique!")
                        # we write duplicate entries from the input list to the resolved list as well
                        # the resolved list should have the same size as the input list
                        if args.resolve:
                            resolved_entries_f.write(str(idno) + ' ' + str(idno_prev) + '\n')
                        if args.get_old:
                            old_entries_f.write(column_left + ' ' + str(idno) + ' ' + column_right + '\n')

        if args.resolve:
            resolved_entries_f.close()
            # we sort the resolved entries by their provisional key to create an output file of primary keys that has the same ordering as the input file
            # this provides an easy mapping from input rows -> final primary keys
            # using this resolution technique to resolve foreign keys allows for the population of relational tables
            with subprocess.Popen(["sort", "-k1,1n", resolved_entries_fn], stdout=subprocess.PIPE) as proc_resolve:
                for line in proc_resolve.stdout:
                    print(line.decode('utf-8').split(' ')[1], end='')

        # concatenate the new entries onto the old ones and voila! your database has been updated
        # note that this process is still valid even when the existing database is empty
        new_entries_f.seek(0)
        database_f = open(args.dest, 'a')
        subprocess.call(["cat", new_entries_fn], stdout=database_f)
        database_f.close()

        sys.stderr.write("{} new entries found\n".format(curr_new))

    finally:
        if args.resolve:
            resolved_entries_f.close()
            os.remove(resolved_entries_fn)
        if args.get_old:
            old_entries_f.close()
        new_entries_f.close()
        os.remove(new_entries_fn)
                    
args = parser.parse_args()
if not args.dest:
    args.dest = args.old
main(args)
