import psycopg2
import os


for machine in machines:
    hostname, port = machine
    #run proc.sql on each machine
    os.system(f'psql -h {hostname} -p {port} -U tinuser -d tin -f proc.sql')


     