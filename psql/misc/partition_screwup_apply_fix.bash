BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
psql -p $1 -d tin -U tinuser -f $BINDIR/../tin/patches/partition/code.pgsql
psql -p $1 -d tin -U tinuser -f $BINDIR/partition_screwup_fix.pgsql
