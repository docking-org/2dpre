import os
import sys

def get_tranches(host,port,BINDIR):
    tranches = []
    mp_range = open(BINDIR+"/mp_range.txt", "r").read().split('\n')
    partitions = open(BINDIR+"/partitions.txt", "r").read().split('\n')
    database_partitions = open(BINDIR+"/database_partitions.txt", "r").read().split('\n')
    db_parts = []
    hosts = []
    for i in database_partitions:
        db_parts.append(i.split(' '))
        hosts.append(i.split(' ')[0])

    #if host:port not in first col of database_partitions.txt, then exit
    partition_id = None
    if host+":"+port not in hosts:
        print("host:port not in database_partitions.txt")
        sys.exit(1)
    else:
        partition_id = db_parts[hosts.index(host+":"+port)][1]

        
    start= None
    end = None
    for i in partitions:
        if i.split(' ')[2] == partition_id:
            start = i.split(' ')[0]
            end = i.split(' ')[1]
            break
        
    hac_start = start[0:3]
    hac_end = end[0:3]
    
    mp_start = mp_range.index(start[3:])
    mp_end = mp_range.index(end[3:])
    
    if hac_start < hac_end:
        for i in range(mp_start, len(mp_range)):
            tranches.append(hac_start + mp_range[i])
        for i in range(0, mp_end+1):
            tranches.append(hac_end + mp_range[i])
    else:
        for i in range(mp_start, mp_end+1):
            tranches.append(hac_start + mp_range[i])
    
    return tranches

if __name__ == '__main__':
    #program takes host, port as arguments
    host = sys.argv[1]
    port = sys.argv[2]
    BINDIR = sys.argv[3]
    tranches = get_tranches(host,port, BINDIR)
    print(tranches)