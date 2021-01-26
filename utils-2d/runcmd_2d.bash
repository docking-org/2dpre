#!/bin/bash
#req: $1: command to run
#opt: SBATCH_ARGS
#opt: SKIP_MACHINES

BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}

function exists_warning {
        env_name=$1
        desc=$2
        default=$3
        if [ -z "${!env_name}" ]; then
                echo "optional env arg missing: $env_name"
                echo "arg description: $desc"
                ! [ -z $default ] && echo "defaulting to $default"
                export $env_name="$default"
        fi
}

runcmd=$@
[ -z $runcmd ] && echo "please supply a command" && exit 1

exists_warning SKIP_MACHINES "comma separated list of machines to exclude from running commands, ex: n-1-17,n-1-18" ""
exists_warning SBATCH_ARGS "optional arguments to supply to sbatch, ex: -J export2d" 

machines=$(cat $BINDIR/machines.txt)
if ! [ -z "$SKIP_MACHINES" ]; then
	skip_newl=$(printf "${SKIP_MACHINES}" | tr ',' '\n')
	machines=$(printf "${machines}\n${skip_newl}" | sort | uniq -u)
fi

echo "cmd: $runcmd"
echo "hosts: $(printf "$machines" | tr '\n' ',')"

echo "sleeping for 3 sec, ctrl-C to cancel"
sleep 3

for host in $machines; do
	jid=$(sbatch --parsable $SBATCH_ARGS -w $host -c "$runcmd")
	echo "submitted $jid to $host"
done
