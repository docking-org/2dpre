# this script loads the specified catalog into the cat_substance_cat table, since we can't do it all at once.
# we shouldn't need to run this again any time soon 
import os
import sys
import argparse
import subprocess


parser = argparse.ArgumentParser(description='Consolidate files')
parser.add_argument('--folder', type=str, help='folder to consolidate')
parser.add_argument('--machine', type=str, help='folder to consolidate', default=None)
args = parser.parse_args()
folder = args.folder
machine = args.machine

os.chdir(folder)

if machine:
    host = machine.split(':')[0]
    port = machine.split(':')[-1]
    os.chdir(machine+'/catsub')
    if not os.path.exists('combined'):
        os.system('cat * > combined')
    if not os.path.getsize('combined') == 0:
        path_to_combined = os.getcwd() + '/combined'
        
        num_cols = int(subprocess.check_output('awk ' + '\'{print NF; exit}\' ' + path_to_combined, shell=True))

        if num_cols == 4:       
            os.system(f'psql -h {host} -p {port} -U tinuser -d tin -f /nfs/home/xyz/btingle/bin/2dload.testing/proc.sql -v folder=\'{path_to_combined}\'')
        elif num_cols == 3:
            os.system(f'psql -h {host} -p {port} -U tinuser -d tin -f /nfs/home/xyz/btingle/bin/2dload.testing/proc2.sql -v folder=\'{path_to_combined}\'')
else:
    for f in os.listdir():

        total = int(subprocess.check_output('ls -l | wc -l ', shell=True)) - 1
        current = 0
        print(f)
        host_name = f.split(':')[0]
        port = f.split(':')[-1]
        print(host_name, port)        
        
        os.chdir(os.getcwd() + '/' + f + '/catsub')
        # for every file in  the folder, run the psql command
        for file in os.listdir():
            print(file)
            size = int(subprocess.check_output('wc -l ' + file, shell=True).split()[0])
            if size > 0:
                print(os.system('tail -n 1 ' + file))
                path_to_file = os.getcwd() + '/' + file
                
                #if combined has 4 cols, run proc.sql, else run proc2.sql
                num_cols = int(subprocess.check_output('awk ' + '\'{print NF; exit}\' ' + path_to_file, shell=True))
                if num_cols == 4:
                    os.system(f'psql -h {host_name} -p {port} -U tinuser -d tin -f /nfs/home/xyz/btingle/bin/2dload.testing/proc.sql -v folder=\'{path_to_file}\'')
                else :
                    os.system(f'psql -h {host_name} -p {port} -U tinuser -d tin -f /nfs/home/xyz/btingle/bin/2dload.testing/proc2.sql -v folder=\'{path_to_file}\'')
            #print progress bar
            current += 1
            print(f'Progress: {current}/{total}')
        os.chdir('../..')  
            

