#!/bin/python
from __future__ import print_function
import sys
import os
from datetime import datetime
from datetime import date
import subprocess
import shutil
import re
import gzip
from export_zinc_ids import export_to_file

LOAD_BASE_DIR = os.environ.get("LOAD_BASE_DIR") or '/local2/load'
BINPATH = os.path.dirname(__file__) or '.'

def log(*message):
    timestr = datetime.now().strftime("%m.%d.%H.%M")
    print("[" + timestr + "]:", *message)

def get_partition_label(no):
    with open(BINPATH + '/partitions.txt') as partf:
        for line in partf:
            start, end, n = line.strip().split()
            if int(n) == no:
                return start + '_' + end
    return "H00P000_H00P000"  

def fixed_width(string, width):
    if len(string) >= width:
        return string[0:width]
    else:
        return string + ' '*(width-len(string))

def append_file(source, dest, chunksize=1024*1024):
    chunk = source.read(chunksize)
    # the file we're reading from may be bytes or text, but the file we're reading to will always be text
    if isinstance(chunk, str):
        while chunk:
            dest.write(chunk)
            chunk = source.read(chunksize)
    else:
        chunk = chunk.decode('utf-8')
        while chunk:
            dest.write(chunk)
            chunk = source.read(chunksize).decode('utf-8')

def append_file_b(source, dest, chunksize=1024*1024):
    chunk = source.read(chunksize)
    while chunk:
        dest.write(chunk)
        chunk = source.read(chunksize)

def append_file_names(source, dest, chunksize=1024*1024):
    with open(source, 'r') as srcf:
        with open(dest, 'a') as destf:
            append_file(srcf, destf, chunksize)

def archive_shortname(archive):
    return archive.split('_')[1].split('.')[0]

def create_column_file(source, column, name, extra=''):
    column_file = open(name, 'w')
    with subprocess.Popen(["awk", "{print $" + str(column) + ' \" ' + extra + '\"}', source], stdout=subprocess.PIPE) as awk_proc:
        append_file(awk_proc.stdout, column_file)
    column_file.close()

def int_from_file(filename):
    n = 0
    if os.path.isfile(filename):
        with open(filename, 'r') as intfile:
            n = int(intfile.read().strip())
    return n

def int_to_file(n, filename):
    with open(filename, 'w') as intfile:
        intfile.write(str(n))

def filedb_add(orig, new, length, dest=None, resolve=False, columns=None, idcolumn=None):
    num_resolved = 0
    filedb_cmd = ["python", BINPATH + "/filedb.py", orig, new, "--length=" + str(length)]
    filedb_cmd += ["--resolve"] if resolve else []
    filedb_cmd += ["--columns={}".format(','.join([str(c) for c in columns]))] if columns else []
    filedb_cmd += ["--dest={}".format(dest)] if dest else []
    filedb_cmd += ["--id-column={}".format(idcolumn)] if idcolumn else []
    resolved_file = open(new + '.r', 'w') if resolve else None
    with subprocess.Popen(filedb_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as filedb_proc:
        if resolve:
            append_file(filedb_proc.stdout, resolved_file)
        error = filedb_proc.stderr.read()
        print(error.decode('utf-8'), end='')
        num_resolved = int(error.split()[0])
    return num_resolved

def linecount(filename):
    n = 0
    with open(filename, 'r') as f:
        chunk = f.read(1024*1024)
        while chunk:
            n += chunk.count('\n')
            chunk = f.read(1024*1024)
    return n

def clear_files(directory):
    for f in list(filter(lambda x:os.path.isfile(directory + '/' + x), os.listdir(directory))):
        os.remove(directory + '/' + f)
    for d in list(filter(lambda x:os.path.isdir(directory + '/' + x), os.listdir(directory))):
        shutil.rmtree(directory + '/' + d)

def is_gz_file(filepath):
    with open(filepath, 'rb') as test_f:
        return test_f.read(2) == b'\x1f\x8b'

def subprocess_call_suppress_error(command, **kwargs):
    with open("/dev/null", 'w') as void:
        subprocess.call(command, stderr=void, **kwargs)

def archive_file(name, dest, length):
    subprocess_call_suppress_error(["mv", name, dest])
    subprocess.call(["gzip", dest])
    length_file_name = os.path.dirname(dest) + '/.' + os.path.basename(dest) + 'l'
    int_to_file(length, length_file_name)

# some of the legacy archives are botched and include a bunch of unnecessary leading components
# e.g 10.20.18.20_su/sub.gz becomes something like: /local2/load/HVVPXXX_HYYPZZZ/src/HVVPXXX/10.20.18.20_su/sub.gz
# we have to use a workaround here to avoid them
def det_leading_components(tarfile, target_string):
    tar_args = '-tzf' if is_gz_file(tarfile) else '-tf'
    with subprocess.Popen(["tar", tar_args, tarfile], stdout=subprocess.PIPE) as tar_proc:
        # take the first line and see where the untarred tarball name is in the path
        # the number of '/'s before the tarball name is what we are interested in trimming down
        for line in tar_proc.stdout:
            components = line.decode('utf-8').strip().split('/')
            target_index = components.index(target_string)
            return target_index

# option 1: add new data to the database
# ex:
# python 2dload.py add 110 results_110_s.pre s
if sys.argv[1] == "add":

    partition_no = int(sys.argv[2])
    prefilename = sys.argv[3]
    catalog_short = sys.argv[4]
    partition_label = get_partition_label(partition_no)
    source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'
    stage_dir = source_dir + '/.stage'
    temp_dir = source_dir + '/.tmp'

    if not prefilename.endswith(".pre"):
        print("database add expects a .pre preprocessing result file")
        exit()

    subprocess.call(["mkdir", "-p", source_dir])
    subprocess.call(["mkdir", "-p", stage_dir ])
    subprocess.call(["mkdir", "-p", temp_dir  ])
    clear_files(temp_dir)
    subprocess.call(["tar", "-C", temp_dir, "-xf", prefilename])

    input_tranches = sorted(os.listdir(temp_dir))
    istranche = lambda t: len(t) == 7 and t[0] == 'H' and (t[3] == 'P' or t[3] == 'M')
    all_tranches = sorted(list(filter(istranche, os.listdir(source_dir))))
    if len(input_tranches) < len(all_tranches):
        log("input .pre file missing {} tranches!".format(len(all_tranches)-len(input_tranches)))
        missing = []
        for tranche in all_tranches:
            if not tranche in input_tranches:
                missing.append(tranche)
        log("missing=" + ','.join(missing))
        sys.exit(1)

    clear_files(stage_dir)
    for i, tranche in enumerate(sorted(os.listdir(temp_dir))):
        log("working on", tranche, catalog_short)
        
        fullpath = stage_dir + '/' + tranche
        srcpath = source_dir + '/' + tranche
        if not os.path.isdir(srcpath):
            subprocess.call(["mkdir", "-p", srcpath])

        create_column_file(temp_dir + '/' + tranche, 1, fullpath + '.sub', extra="MISSING")
        create_column_file(temp_dir + '/' + tranche, 2, fullpath + '.sup', extra=str(i+1))

        length_org_substance = int_from_file(source_dir + '/.len_substance')
        length_org_supplier  = int_from_file(source_dir + '/.len_supplier')
        length_org_catalog   = int_from_file(source_dir + '/.len_catalog')

        new_entries_sub_fn = fullpath + '.sub.new'
        new_entries_sup_fn = fullpath + '.sup.new'
        log("adding new substance data...")
        length_new_substance = filedb_add(srcpath + '/substance.txt', fullpath + '.sub', length_org_substance, resolve=True, dest=new_entries_sub_fn, columns=[1])
        log("adding new supplier data...")
        length_new_supplier  = filedb_add(srcpath + '/supplier.txt',  fullpath + '.sup', length_org_supplier,  resolve=True, dest=new_entries_sup_fn, idcolumn=2, columns=[1])

        catalog_new_file = open(fullpath + '.cat', 'w')
        with subprocess.Popen(["paste", "-d", " ", fullpath + '.sub.r', fullpath + '.sup.r'], stdout=subprocess.PIPE) as paste_proc:
            append_file(paste_proc.stdout, catalog_new_file)
        catalog_new_file.close()

        new_entries_cat_fn = fullpath + '.cat.new'
        log("adding new catalog data...")
        length_new_catalog   = filedb_add(srcpath + '/catalog.txt',   fullpath + '.cat', length_org_catalog, dest=new_entries_cat_fn, columns=[1, 2])

        int_to_file(length_new_substance+length_org_substance, source_dir + '/.len_substance')
        int_to_file(length_new_supplier+length_org_supplier,   source_dir + '/.len_supplier')
        int_to_file(length_new_catalog+length_org_catalog,     source_dir + '/.len_catalog')

        if length_new_catalog == 0:
            log("no new entries detected, empty archive will be created")
            #continue

        append_file_names(new_entries_sub_fn, srcpath + '/substance.txt')
        append_file_names(new_entries_sup_fn, srcpath + '/supplier.txt')
        append_file_names(new_entries_cat_fn, srcpath + '/catalog.txt')

        def find_existing_archives(catalog_short, sourcedir):
            archives = list(filter(lambda x:x.endswith('.tar.gz'), os.listdir(sourcedir)))
            shortmatch = re.compile('.*_({})(\d?).*'.format(catalog_short))
            latest = -1
            for archive in archives:
                match = shortmatch.match(archive)
                if not match:
                    continue
                shortname = match.group(1)
                updatenum = int(match.group(2)) if match.group(2) else 0
                latest = updatenum if updatenum > latest else latest
            return latest + 1

        timestr = datetime.now().strftime("%m.%d.%H.%M")
        updatenum = find_existing_archives(catalog_short, srcpath)
        archivename = timestr + '_' + catalog_short + (str(updatenum) if updatenum else '')
        archivetmpdir = stage_dir + '/' + archivename
        os.mkdir(archivetmpdir)
        archive_file(new_entries_sub_fn, archivetmpdir + '/sub', length_new_substance)
        archive_file(new_entries_sup_fn, archivetmpdir + '/sup', length_new_supplier)
        archive_file(new_entries_cat_fn, archivetmpdir + '/cat', length_new_catalog)
        subprocess.call(["tar", "-C", stage_dir, "-czf", srcpath + '/' + archivename + '.tar.gz', archivename])

        log("success! results archived to {}".format(srcpath + '/' + archivename + '.tar.gz'))

        #shutil.rmtree(archivetmpdir)
        clear_files(stage_dir)
    clear_files(temp_dir)

# option 2: roll back to a previous version, or view the existing versions
if sys.argv[1] == "rollback":

    partition_no = int(sys.argv[2])
    print(partition_no)
    partition_label = get_partition_label(partition_no)
    
    # view existing versions
    if sys.argv[3] == "list":

        print(fixed_width("tranche", 7) + '|' + fixed_width("date", 15) + '|' + fixed_width("short", 7) + '|' + fixed_width("catalog size", 15))
        print('='*7 + '|' + '='*15 + '|' + '='*7 + '|' + '='*15)

        source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'

        istranche = lambda t: len(t) == 7 and t[0] == 'H' and (t[3] == 'P' or t[3] == 'M')
        sources = sorted(list(filter(istranche, os.listdir(source_dir))))

        for source in sources:
            archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(source_dir + '/' + source)))
            times = sorted([(datetime.strptime(archive[0:11], "%m.%d.%H.%M"), archive) for archive in archives], key=lambda x:x[0])

            for time in times:
                time, archive = time
                short = archive_shortname(archive)
                untarred_archive = '.'.join(archive.split('.')[:-2])
                tar_args = "-xzf" if is_gz_file(source_dir + '/' + source + '/' + archive) else "-xf"
                # suppress error message if .catl file is not present in archive
                subprocess_call_suppress_error(["tar", tar_args, source_dir + '/' + source + '/' + archive, untarred_archive + "/.catl"])
                if os.path.isfile(untarred_archive + "/.catl"):
                    size = str(int_from_file(untarred_archive + "/.catl"))
                    shutil.rmtree(untarred_archive)
                else:
                    size = "legacy archive"
                print(fixed_width(source, 7) + '|' + fixed_width(archive[0:11], 15) + '|' + fixed_width(short, 7) + '|' + fixed_width(size, 15))
            print("=" * 47)

        sub_total = int_from_file(source_dir + '/.len_substance')
        sup_total = int_from_file(source_dir + '/.len_supplier')
        cat_total = int_from_file(source_dir + '/.len_catalog')
        log("total substance table size: {}".format(sub_total))
        log("total supplier table size:  {}".format(sup_total))
        log("total catalog table size:   {}".format(cat_total))

    # rollback to previous version
    else:

        shortname_list = sys.argv[3].split(',')
        source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'

        # use a less restrictive lambda here so we can implement a dirty hack
        # basically, in order to keep legacy compatibility, we need to be able to have len_substance be greater than the actual length
        # to accomplish this we need to have a "dummy" tranche with some dummy entries that count towards the total length, but aren't included in the database proper
        # since len_substance is calculated from scratch on rollback, we need to have the rollback function recognize this dummy tranche, but only the rollback function
        sources = sorted(list(filter(lambda x:not x.startswith('.'), os.listdir(source_dir))))

        new_length_substance = 0
        new_length_supplier = 0
        new_length_catalog = 0

        for source in sources:

            source_path = source_dir + '/' + source
            log("working on " + source_path)
            try:
                os.remove(source_path + '/substance.txt')
                os.remove(source_path + '/catalog.txt')
                os.remove(source_path + '/supplier.txt')
            except:
                pass

            substance_file  = open(source_path + '/substance.txt',  'w')
            catalog_file    = open(source_path + '/catalog.txt',    'w')
            supplier_file   = open(source_path + '/supplier.txt',   'w')

            try:
                archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(source_path)))
                times = sorted([(datetime.strptime(archive[0:11], "%m.%d.%H.%M"), archive) for archive in archives], key=lambda x:x[0])

                for time in times:
                    time, archive = time
                    short = archive_shortname(archive)
                    log("working on archive {}".format(short))
                    if not (short in shortname_list):
                        os.remove(source_path + '/' + archive)
                        print("encountered not on list")
                        continue
                    archive_path    = source_path   + '/' + archive
                    untarred_path   = source_path   + '/' + '.'.join(archive.split('.')[:-2])
                    substance_path  = untarred_path + '/sub'
                    catalog_path    = untarred_path + '/cat'
                    supplier_path   = untarred_path + '/sup'

                    # see comment at definition of det_leading_components
                    strip_components = det_leading_components(archive_path, os.path.basename(untarred_path))
                    # funny enough, some legacy archives are labeled "tar.gz" files, but aren't actually gzipped. Deal with this here
                    tar_args = "-xzf" if is_gz_file(archive_path) else "-xf"
                    subprocess.call(["tar", "--strip-components={}".format(strip_components), "-C", source_path, tar_args, archive_path])
                    subprocess.call(["gzip", "-d", substance_path + '.gz'])
                    subprocess.call(["gzip", "-d", catalog_path   + '.gz'])
                    subprocess.call(["gzip", "-d", supplier_path  + '.gz'])

                    lengthfile = lambda path: os.path.dirname(path) + '.' + os.path.basename(path) + 'l'
                    this_length_substance = int_from_file(lengthfile(substance_path)) if os.path.isfile(lengthfile(substance_path)) else linecount(substance_path)
                    this_length_supplier  = int_from_file(lengthfile(supplier_path )) if os.path.isfile(lengthfile(supplier_path )) else linecount(supplier_path)
                    this_length_catalog   = int_from_file(lengthfile(catalog_path  )) if os.path.isfile(lengthfile(catalog_path  )) else linecount(catalog_path)

                    with open(substance_path) as sub_file:
                        append_file(sub_file, substance_file)
                    with open(catalog_path) as cat_file:
                        append_file(cat_file, catalog_file)
                    with open(supplier_path) as sup_file:
                        append_file(sup_file, supplier_file)

                    if not os.path.isfile(lengthfile(substance_path)):
                        archive_file(substance_path, substance_path, this_length_substance)
                        archive_file(supplier_path, supplier_path, this_length_supplier)
                        archive_file(catalog_path, catalog_path, this_length_catalog)
                        subprocess.call(["tar", "-C", source_path, "-czf", archive_path, os.path.basename(untarred_path)])
                    
                    new_length_substance += this_length_substance
                    new_length_supplier += this_length_supplier
                    new_length_catalog += this_length_catalog
                    shutil.rmtree(untarred_path)
            finally:
                substance_file.close()
                catalog_file.close()
                supplier_file.close()
        
        int_to_file(new_length_substance, source_dir + '/.len_substance')
        int_to_file(new_length_supplier,  source_dir + '/.len_supplier')
        int_to_file(new_length_catalog,   source_dir + '/.len_catalog')

# option 3- export substance data from database
if sys.argv[1] == "export":

    partition_no = int(sys.argv[2])
    partition_label = get_partition_label(partition_no)
    shortnames = [] # by default this command will export all SMILES in the database
    source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'

    # alternatively, you can select catalog(s) to export
    if len(sys.argv) > 3:
        shortnames = list(map(str, sys.argv[3].split(',')))
    selected = os.getenv("EXPORT_TRANCHE")

    istranche = lambda t: len(t) == 7 and t[0] == 'H' and (t[3] == 'P' or t[3] == 'M')
    sources = sorted(list(filter(istranche, os.listdir(source_dir))))

    for source in sources:
        if selected and not (source == selected):
            continue
        log(source)

        srcdir = source_dir + '/' + source
        archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(srcdir)))
        export_archives = []

        for archive in archives:
            catalog_short = archive_shortname(archive)
            if not shortnames or catalog_short in shortnames:
                export_archives.append(archive)

        export_file = open(source + '.' + '.'.join(shortnames + ['smi']), 'w')

        for export in export_archives:

            archive_path    = srcdir   + '/' + export
            untarred_path   = srcdir   + '/' + '.'.join(export.split('.')[:-2])
            substance_path  = untarred_path + '/sub'
            strip_components = det_leading_components(archive_path, os.path.basename(untarred_path))
            tar_args = "-xzf" if is_gz_file(archive_path) else "-xf"
            if os.path.isdir(untarred_path): shutil.rmtree(untarred_path)
            subprocess.call(["tar", "--strip-components={}".format(strip_components), "-C", srcdir, tar_args, archive_path, '.'.join(export.split('.')[:-2]) + '/sub.gz'])
            subprocess.call(["gzip", "-d", substance_path + '.gz'])

            export_to_file(substance_path, export_file, source, BINPATH)
            shutil.rmtree(untarred_path)

        export_file.close()

# option 4- query, wipe, or upload data to the postgres DBMS
if sys.argv[1] == "postgres":

    def bind_port(port_no, partition_dir):
        with open(partition_dir + '/.port') as portfile:
            portfile.write("{}".format(port_no))

    partition_no = int(sys.argv[2])
    partition_label = get_partition_label(partition_no)
    upload_type = sys.argv[3]
    if len(sys.argv) > 4:
        postgres_port = int(sys.argv[4])
    else:
        postgres_port = int_from_file(LOAD_BASE_DIR + '/' + partition_label + '/.port')
    source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'
    psql = ["psql", "-d", "tin", "-U", "tinuser"]

    def query_present(source, port, verbose=False):
        results = []
        istranche = lambda t: len(t) == 7 and t[0] == 'H' and (t[3] == 'P' or t[3] == 'M')
        sources = sorted(list(filter(istranche, os.listdir(source))))

        for src in sources:
            fullpath = source + '/' + src
            archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(fullpath)))

            for archive in archives:
                archive_path    = fullpath   + '/' + archive
                untarred_path   = fullpath   + '/' + '.'.join(archive.split('.')[:-2])
                substance_path  = untarred_path + '/sub'
                supplier_path   = untarred_path + '/sup'
                catalog_path    = untarred_path + '/cat'
                strip_components = det_leading_components(archive_path, os.path.basename(untarred_path))
                tar_args = "-xzf" if is_gz_file(archive_path) else "-xf"
                subprocess.call(["tar", "--strip-components={}".format(strip_components), "-C", fullpath, tar_args, archive_path])

                def query_present(pkey_column, pkey_name, table_name, testpath):
                    with gzip.open(testpath) as testfile:
                        head = testfile.readline()
                        if not head:
                            return -1
                        tokens = head.split()
                        pkey = tokens[pkey_column-1]
                        with subprocess.Popen(
                            psql + ["-p", str(port), "--csv", "-c", "select {} from {} where ( {} = {} ) limit 1".format(pkey_name, table_name, pkey_name, int(pkey))], stdout=subprocess.PIPE) as psql_query:
                            skip = psql_query.stdout.readline()
                            present = psql_query.stdout.readline()
                            if present:
                                return 0
                            return 1
                if verbose: print("working on: " + archive, end='\r')

                subtest = query_present(3, "sub_id", "substance", substance_path + '.gz')
                suptest = query_present(2, "cat_content_id", "catalog_content", supplier_path + '.gz')
                cattest = query_present(3, "cat_sub_itm_id", "catalog_substance", catalog_path + '.gz')
                
                if suptest == 1 or subtest == 1 or cattest == 1:
                    if suptest == 0 or subtest == 0 or cattest == 0:
                        log("some tables were present in {} while others weren't: sup:{} sub:{} cat:{}".format(archive_path, suptest, subtest, cattest))
                        sys.exit(1)
                    results.append((archive_path, False))
                    log("{} will upload".format(archive_path))
                else:
                    if suptest == -1 and subtest == -1 and cattest == -1:
                        log("{} empty, no upload".format(archive_path))
                    else:
                        log("{} found, no upload".format(archive_path))
                    results.append((archive_path, True))
                
                shutil.rmtree(untarred_path)
        if verbose: print()
        return results

    def wipe_postgres(port):

        subprocess.call(psql + ["-p", str(port), "-f", BINPATH + '/psql/tin_wipe.psql'])

    def upload_archives(archives, port, upload_full=0):

        if len(archives) == 0:
            log("nothing to upload!")
            return

        to_upload_sub = open("/tmp/{}.to_upload.sub".format(port), 'w')
        to_upload_sup = open("/tmp/{}.to_upload.sup".format(port), 'w')
        to_upload_cat = open("/tmp/{}.to_upload.cat".format(port), 'w')
        new_archives = []
        for upload in archives:

            source_path     = os.path.dirname(upload)
            untarred_path   = '.'.join(upload.split('.')[:-2])
            substance_path  = untarred_path + '/sub'
            catalog_path    = untarred_path + '/cat'
            supplier_path   = untarred_path + '/sup'
            shortname       = os.path.basename(untarred_path).split('_')[1]

            if os.path.isdir(untarred_path):
                shutil.rmtree(untarred_path)
            strip_components = det_leading_components(upload, os.path.basename(untarred_path))
            tar_args = "-xzf" if is_gz_file(upload) else "-xf"
            subprocess.call(["tar", "--strip-components={}".format(strip_components), "-C", source_path, tar_args, upload])
            subprocess.call(["gzip", "-d", substance_path + '.gz'])
            subprocess.call(["gzip", "-d", catalog_path   + '.gz'])
            subprocess.call(["gzip", "-d", supplier_path  + '.gz'])
            # trim any trailing whitespace, it will mess with postgres
            subprocess.call(["sed", "-i", "s/\s*$//g", substance_path])
            subprocess.call(["sed", "-i", "s/\s*$//g", supplier_path])
            subprocess.call(["sed", "-i", "s/\s*$//g", catalog_path])

            new_archives.append((source_path, untarred_path, (substance_path, catalog_path, supplier_path), shortname))

            #source_path, untarred_path, archive_paths, shortname = upload
            #supplier_path = archive_paths[2]

            # our default supplier.txt doesn't have catalog mapping information that postgres wants
            # sooo instead of retrofitting everything we will just fix at upload time
            catid = None
            with subprocess.Popen(psql + ["-p", str(port), "--csv", "-c", "select (cat_id) from catalog where ( name = '{}' )".format(shortname)], stdout=subprocess.PIPE) as catquery:
                header = catquery.stdout.readline()
                catid = catquery.stdout.readline()
                if not catid:
                    todaysdate = date.today().strftime("%B %d, %Y")
                    with subprocess.Popen(psql + ["-p", str(port), "--csv", "-c", "insert into catalog (name, short_name, updated) values ('{}', '{}', '{}') returning cat_id".format(shortname, shortname, todaysdate)], stdout=subprocess.PIPE) as insertcat:
                        header = insertcat.stdout.readline()
                        catid = insertcat.stdout.readline()
            catid = str(int(catid))
            supplier_catid_f = open(supplier_path + '.psql', 'w')
            subprocess.call(["awk", "-v", "catid={}".format(catid), "{print $1 \" \" $2 \" \" catid}", supplier_path], stdout=supplier_catid_f)
            supplier_catid_f.close()

            to_upload_sub.write(substance_path + '\n')
            to_upload_sup.write(supplier_path + '.psql' + '\n')
            to_upload_cat.write(catalog_path + '\n')

            #supplier_catid_f = open(supplier_path + '.psql', 'rb')
            #append_file(supplier_catid_f, psql_process.stdin)

            #shutil.rmtree(untarred_path)

        to_upload_sub.close()
        to_upload_sup.close()
        to_upload_cat.close()

        upload_var_args = []
        upload_var_args.append("--set=to_copy_sub={}".format("/tmp/{}.to_upload.sub".format(port)))
        upload_var_args.append("--set=to_copy_sup={}".format("/tmp/{}.to_upload.sup".format(port)))
        upload_var_args.append("--set=to_copy_cat={}".format("/tmp/{}.to_upload.cat".format(port)))
        upload_var_args.append("--set=upload_full={}".format(upload_full))

        psql_process = subprocess.Popen(psql + ["-p", str(port), "--csv"] + upload_var_args + ["-f", BINPATH + '/psql/tin_master_copy.pgsql'])

        #psql_process.stdin.close()

        log("finished the python side of things, waiting for postgres to finish")
        psql_process.wait()

    # upload strategy 0: query postgres to see which data is present, don't upload any data
    if upload_type == "query":
        present_query = query_present(source_dir, postgres_port, verbose=True)
        print(fixed_width("archive name", 64) + ' | ' + fixed_width("present", 8) + ' |')
        for result in present_query:
            archive, present = result
            print(fixed_width(archive, 64) + ' | ' + fixed_width(str(present), 8) + ' |')

    # upload strategy 1: wipe the existing database
    if upload_type == "clear":
        are_you_sure_about_this = input("are you sure you want to wipe the existing database? ctrl-C to cancel")
        wipe_postgres(postgres_port)

    # upload strategy 2: find data not currently present on postgres and upload that data
    if upload_type == "upload_smart":
        present_query = query_present(source_dir, postgres_port)
        to_upload = [x[0] for x in filter(lambda x:not x[1], present_query)]

        log("uploading {} archives".format(len(to_upload)))
        upload_archives(to_upload, postgres_port, upload_full=0)


    # upload strategy 3: remove any data present on postgres, upload everything in full
    if upload_type == "upload_full":

        all_archives = [x[0] for x in query_present(source_dir, postgres_port)]
        upload_archives(all_archives, postgres_port, upload_full=1)

    if upload_type == "bind":
        int_to_file(postgres_port, LOAD_BASE_DIR + '/' + partition_label + '/.port')
