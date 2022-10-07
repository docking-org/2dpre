user=$1
pwfile=$2
statsout=$3
# source sshpass
export PATH=$PATH:~/sshpass-install/bin
for m in $(cat common_files/machines.txt common_files/antimony_machines.txt); do

	mem=$(sshpass -f $pwfile ssh $user@$m free | grep Mem | awk '{print $2}')
	cpu=$(sshpass -f $pwfile ssh $user@$m lscpu | grep -w ^CPU\(s\): | awk '{print $2}')

	echo $m,$mem,$cpu | tee -a $statsout
done
