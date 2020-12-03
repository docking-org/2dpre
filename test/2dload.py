#!/bin/python

import sys
import os
from datetime import datetime
import subprocess
import shutil
import re

LOAD_BASE_DIR = os.environ.get("LOAD_BASE_DIR") or '/local2/load'
BINPATH = os.path.dirname(__file__) or '.'

def get_partition_label(no):
    with open(BINPATH + '/partitions.txt') as partf:
        for line in partf:
            start, end, no = line.split()
            if int(no) == no:
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

def append_file_names(source, dest, chunksize=1024*1024):
    with open(source, 'r') as srcf:
        with open(dest, 'a') as destf:
            append_file(srcf, destf, chunksize)

def archive_shortname(archive):
    return archive.split('_')[1].split('.')[0]

def create_column_file(source, column, name):
    column_file = open(name, 'w')
    with subprocess.Popen(["awk", "{print $" + str(column) + ' }', source], stdout=subprocess.PIPE) as awk_proc:
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

def filedb_add(orig, new, length, dest=None, resolve=False, columns=None):
    num_resolved = 0
    filedb_cmd = ["python3", BINPATH + "/filedb.py", orig, new, "--length=" + str(length)]
    filedb_cmd += ["--resolve"] if resolve else []
    filedb_cmd += ["--columns={}".format(','.join([str(c) for c in columns]))] if columns else []
    filedb_cmd += ["--dest={}".format(dest)] if dest else []
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
    for f in list(filter(lambda x:os.path.isfile(x), os.listdir(directory))):
        os.remove(f)

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
    subprocess.call(["tar", "-C", temp_dir, "-xf", prefilename])

    for tranche in os.listdir(temp_dir):
        print(tranche, catalog_short)
        
        fullpath = stage_dir + '/' + tranche
        srcpath = source_dir + '/' + tranche
        if not os.path.isdir(srcpath):
            subprocess.call(["mkdir", "-p", srcpath])

        create_column_file(temp_dir + '/' + tranche, 1, fullpath + '.sub')
        create_column_file(temp_dir + '/' + tranche, 2, fullpath + '.sup')
    
        length_org_substance = int_from_file(source_dir + '/.len_substance')
        length_org_supplier  = int_from_file(source_dir + '/.len_supplier')
        length_org_catalog   = int_from_file(source_dir + '/.len_catalog')

        new_entries_sub_fn = fullpath + '.sub.new'
        new_entries_sup_fn = fullpath + '.sup.new'
        print("adding new substance data...")
        length_new_substance = filedb_add(srcpath + '/substance.txt', fullpath + '.sub', length_org_substance, resolve=True, dest=new_entries_sub_fn)
        print("adding new supplier data...")
        length_new_supplier  = filedb_add(srcpath + '/supplier.txt',  fullpath + '.sup', length_org_supplier,  resolve=True, dest=new_entries_sup_fn)

        catalog_new_file = open(fullpath + '.cat', 'w')
        with subprocess.Popen(["paste", "-d", " ", fullpath + '.sub.r', fullpath + '.sup.r'], stdout=subprocess.PIPE) as paste_proc:
            append_file(paste_proc.stdout, catalog_new_file)
        catalog_new_file.close()

        new_entries_cat_fn = fullpath + '.cat.new'
        print("adding new catalog data...")
        length_new_catalog   = filedb_add(srcpath + '/catalog.txt',   fullpath + '.cat', length_org_catalog, dest=new_entries_cat_fn)

        int_to_file(length_new_substance+length_org_substance, source_dir + '/.len_substance')
        int_to_file(length_new_supplier+length_org_supplier,   source_dir + '/.len_supplier')
        int_to_file(length_new_catalog+length_org_catalog,     source_dir + '/.len_catalog')

        if length_new_catalog == 0:
            print("no new entries detected, no archive will be created")
            continue

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

        def archive_file(name, dest, length):
            subprocess.call(["mv", name, dest])
            subprocess.call(["gzip", dest])
            length_file_name = os.path.dirname(dest) + '/.' + os.path.basename(dest) + 'l'
            int_to_file(length, length_file_name)

        timestr = datetime.now().strftime("%m.%d.%H.%M")
        updatenum = find_existing_archives(catalog_short, srcpath)
        archivename = timestr + '_' + catalog_short + (str(updatenum) if updatenum else '')
        archivetmpdir = stage_dir + '/' + archivename
        os.mkdir(archivetmpdir)
        archive_file(new_entries_sub_fn, archivetmpdir + '/sub', length_new_substance)
        archive_file(new_entries_sup_fn, archivetmpdir + '/sup', length_new_supplier)
        archive_file(new_entries_cat_fn, archivetmpdir + '/cat', length_new_catalog)
        subprocess.call(["tar", "-C", stage_dir, "-czf", srcpath + '/' + archivename + '.tar.gz', archivename])

        print("success! results archived to {}".format(srcpath + '/' + archivename + '.tar.gz'))

        clear_files(stage_dir)
        clear_files(temp_dir)

# option 2: roll back to a previous version, or view the existing versions
if sys.argv[1] == "rollback":

    partition_no = int(sys.argv[2])
    partition_label = get_partition_label(partition_no)
    
    if sys.argv[3] == "list":

        print(fixed_width("tranche", 7) + '|' + fixed_width("date", 15) + '|' + fixed_width("short", 7) + '|' + fixed_width("catalog size", 15))
        print('='*7 + '|' + '='*15 + '|' + '='*7 + '|' + '='*15)

        source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'

        sources = list(filter(lambda x:not x.startswith('.'), os.listdir(source_dir)))

        for source in sources:
            archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(source_dir + '/' + source)))
            times = sorted([(datetime.strptime(archive[0:11], "%m.%d.%H.%M"), archive) for archive in archives], key=lambda x:x[0])

            for time in times:
                time, archive = time
                short = archive_shortname(archive)
                untarred_archive = '.'.join(archive.split('.')[:-2])
                subprocess.call(["tar", "-xzf", source_dir + '/' + source + '/' + archive, untarred_archive + "/.catl"])
                if os.path.isfile(untarred_archive + "/.catl"):
                    size = str(int_from_file(untarred_archive + "/.catl"))
                    shutil.rmtree(untarred_archive)
                else:
                    size = "legacy archive"
                print(fixed_width(source, 7) + '|' + fixed_width(archive[0:11], 15) + '|' + fixed_width(short, 7) + '|' + fixed_width(size, 15))
    else:

        shortname_list = sys.argv[3].split(',')
        source_dir = LOAD_BASE_DIR + '/' + partition_label + '/src'
        sources = list(filter(lambda x:not x.startswith('.'), os.listdir(source_dir)))

        new_length_substance = 0
        new_length_supplier = 0
        new_length_catalog = 0

        for source in sources:

            source_path = source_dir + '/' + source
            os.remove(source_path + '/substance.txt')
            os.remove(source_path + '/catalog.txt')
            os.remove(source_path + '/supplier.txt')

            substance_file  = open(source_path + '/substance.txt',  'w')
            catalog_file    = open(source_path + '/catalog.txt',    'w')
            supplier_file   = open(source_path + '/supplier.txt',   'w')

            try:
                archives = list(filter(lambda x:x.endswith("tar.gz"), os.listdir(source_path)))
                times = sorted([(datetime.strptime(archive[0:11], "%m.%d.%H.%M"), archive) for archive in archives], key=lambda x:x[0])

                for time in times:
                    time, archive = time
                    short = archive_shortname(archive)
                    if not (short in shortname_list):
                        os.remove(source_path + '/' + archive)
                        continue
                    print(source_path)
                    archive_path    = source_path   + '/' + archive
                    untarred_path   = source_path   + '/' + '.'.join(archive.split('.')[:-2])
                    substance_path  = untarred_path + '/sub'
                    catalog_path    = untarred_path + '/cat'
                    supplier_path   = untarred_path + '/sup'

                    subprocess.call(["tar", "-C", source_path, "-xzf", archive_path])
                    subprocess.call(["gzip", "-d", substance_path + '.gz'])
                    subprocess.call(["gzip", "-d", catalog_path   + '.gz'])
                    subprocess.call(["gzip", "-d", supplier_path  + '.gz'])

                    lengthfile = lambda path: os.path.dirname(path) + '.' + os.path.basename(path) + 'l'
                    new_length_substance += int_from_file(lengthfile(substance_path)) if os.path.isfile(lengthfile(substance_path)) else linecount(substance_path)
                    new_length_supplier  += int_from_file(lengthfile(supplier_path )) if os.path.isfile(lengthfile(supplier_path )) else linecount(supplier_path)
                    new_length_catalog   += int_from_file(lengthfile(catalog_path  )) if os.path.isfile(lengthfile(catalog_path  )) else linecount(catalog_path)

                    with open(substance_path) as sub_file:
                        append_file(sub_file, substance_file)
                    with open(catalog_path) as cat_file:
                        append_file(cat_file, catalog_file)
                    with open(supplier_path) as sup_file:
                        append_file(sup_file, supplier_file)

                    shutil.rmtree(untarred_path)
            finally:
                substance_file.close()
                catalog_file.close()
                supplier_file.close()
        
        int_to_file(new_length_substance, source_dir + '/.len_substance')
        int_to_file(new_length_supplier,  source_dir + '/.len_supplier')
        int_to_file(new_length_catalog,   source_dir + '/.len_catalog')
            


