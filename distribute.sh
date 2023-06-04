#!/bin/bash

sshport=${1:-22}
passwd=$2
shift 2
hosts=$*

if [ ! -f kunlun_init.sh ] ;then
	echo 'init_file No such file or directory'
	exit
fi


#if [ $USER == "root" ];then
#		echo "Currently root user, unable to execute"
#		exit 

#fi

if [ $# -lt 1 ];then
	echo "Usage:  port passwd ip_list......"
	exit 
fi


if ! rpm -qa |grep -w expect &>/dev/null ;then
	sudo yum install -y expect
fi



for i in $hosts
do
echo "...............$i.................."
echo "Upload files  kunlun_init.sh to $i"
expect <<EOF

	spawn  scp -P$sshport  -rp kunlun_init.sh   root@$i:/root/ 
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF
done 




for k in $hosts
do
echo "...............$k.................."
echo "Run script kunlun_init.sh on $k"
expect <<EOF

	spawn  ssh -p$sshport  root@$k   "test -f  /root/kunlun_init.sh  && sh /root/kunlun_init.sh"
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF
done 





