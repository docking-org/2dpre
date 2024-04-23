#start tin/antimony postgres instances that are not running
#call sudo service postgresql$-12 start, where 5435 = 1, 5436 =2, etc
#https://www.youtube.com/watch?v=4j_cOsgRY7w
import psycopg2
import os 
import paramiko 

import logging


class SSH:
    def __init__(self):
        pass

    def get_ssh_connection(self, ssh_machine, ssh_username, ssh_password):
        """Establishes a ssh connection to execute command.
        :param ssh_machine: IP of the machine to which SSH connection to be established.
        :param ssh_username: User Name of the machine to which SSH connection to be established..
        :param ssh_password: Password of the machine to which SSH connection to be established..
        returns connection Object
        """
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        client.connect(hostname=ssh_machine, username=ssh_username, password=ssh_password, timeout=10)
        return client
        
    def run_sudo_command(self, ssh_username="s_mar", ssh_password="mypassword", ssh_machine="localhost", command="ls",
                            jobid="None"):
        """Executes a command over a established SSH connectio.
        :param ssh_machine: IP of the machine to which SSH connection to be established.
        :param ssh_username: User Name of the machine to which SSH connection to be established..
        :param ssh_password: Password of the machine to which SSH connection to be established..
        returns status of the command executed and Output of the command.
        """
        conn = self.get_ssh_connection(ssh_machine=ssh_machine, ssh_username=ssh_username, ssh_password=ssh_password)
        command = "sudo -S -p '' %s" % command
        logging.info("Job[%s]: Executing: %s" % (jobid, command))
        stdin, stdout, stderr = conn.exec_command(command=command)
        stdin.write(ssh_password + "\n")
        stdin.flush()
        stdoutput = [line for line in stdout]
        stderroutput = [line for line in stderr]
        for output in stdoutput:
            logging.info("Job[%s]: %s" % (jobid, output.strip()))
        # Check exit code.
        logging.debug("Job[%s]:stdout: %s" % (jobid, stdoutput))
        logging.debug("Job[%s]:stderror: %s" % (jobid, stderroutput))
        logging.info("Job[%s]:Command status: %s" % (jobid, stdout.channel.recv_exit_status()))
        if not stdout.channel.recv_exit_status():
            logging.info("Job[%s]: Command executed." % jobid)
            conn.close()
            if not stdoutput:
                stdoutput = True
            return True, stdoutput
        else:
            logging.error("Job[%s]: Command failed." % jobid)
            for output in stderroutput:
                logging.error("Job[%s]: %s" % (jobid, output))
            conn.close()
            return False, stderroutput


from load_app.common.consts import *

conn = psycopg2.connect(CONFIG_DB_URL)
cur = conn.cursor()
cur.execute('select hostname,port from tin_machines')
sizes = {}
machines = cur.fetchall()
machines = [list(x) for x in machines]

ssh = SSH()
for machine in machines:
    print(machine)
    try:
        connection = ssh.run_sudo_command(ssh_machine=machine[0], ssh_username="s_mar", ssh_password="69Fenderhoe!", command='sudo service postgresql'+str(int(machine[1])-5432)+'-12 start')
    except:
        continue
    print(connection)

antimony_machines = {   
"n-9-38",
"n-5-13",
"n-5-15",
"n-5-14"
}

for machine in antimony_machines:
    try:
        #find postgres services that contain 'sb' in their name and start them
        #8 processes per machine
        for i in range(1,9):
            connection = ssh.run_sudo_command(ssh_machine=machine, ssh_username="s_mar", ssh_password="69Fenderhoe!", command='sudo service postgresql'+str(i)+'sb-12 start')
            print(connection)
    except:
        continue
    


