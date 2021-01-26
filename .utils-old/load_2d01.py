import sys
import os
import subprocess

LOAD_BASE_DIR = os.getenv("LOAD_BASE_DIR") or "/local2/load"
BINPATH = os.path.dirname(__name__) or '.'

def get_partition_no(partition):
	with subprocess.Popen(["grep", partition.split('_')[0], BINPATH + "/partitions.txt"], stdout=subprocess.PIPE) as grep:
		start, end, no = grep.stdout.read().decode('utf-8').split()
		return int(no)

partitions = list(filter(lambda x: len(x) == 15 and x.startswith('H'), os.listdir(LOAD_BASE_DIR)))
jobs = []

for partition in partitions:

	sources = os.listdir(LOAD_BASE_DIR + '/' + partition + '/src')
	for source in sources:

		archives = list(filter(lambda x: x.endswith("tar.gz"), os.listdir(LOAD_BASE_DIR + '/' + partition + '/src/' + source)))

		if not len(archives) == 5:
			no = get_partition_no(partition)
			job = []
			job.append((no, 's'))
			job.append((no, 'm'))
			job.append((no, 'su'))
			job.append((no, 'mu'))
			jobs.append(job)
			break

for job in jobs:
	print("{}, {}".format(job[0][0]))

max_running = 4

queued = []
running = []
while len(queued) < max_running:
	queued.append(jobs.pop(0))

for job in queued:
	pno, catalogue = job.pop(0)
	proc = subprocess.Popen(["python", BINPATH + "../2dload.py", "add", str(pno), "/nfs/exb/zinc22/2dpre_results/{}/{}.pre".format(catalogue, pno), catalogue])
