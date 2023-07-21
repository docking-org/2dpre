import os, sys

BINDIR = os.path.dirname(sys.argv[0]) or '.'
if not BINDIR.startswith('/'):
	BINDIR=os.getcwd()+'/'+BINDIR
LOGDIR = BINDIR+'/logs'
BIG_SCRATCH_DIR = "/local2/load"
TARGET_PARTITION_SIZE = 512000000
CONFIG_DB_HOST='n-1-17'
CONFIG_DB_PORT='5534'
CONFIG_DB_USER='zincuser'
CONFIG_DB_NAME='zinc22_common'
