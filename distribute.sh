#!/bin/bash

user=$1
passwd=$2
sshport=$3
file_name=$4
shift 4
hosts=$*

if [ ! -f ${file_name} ] ;then
	echo 'init_file No such file or directory'
	exit
fi


if [ $user != "root" ];then
		echo "The target machine requires root privileges"
		exit 

fi

if [ $# -lt 1 ];then
	echo "Usage:  user passwd port file_name ip_list......"
	exit 
fi

if uname -a|grep Ubuntu &>/dev/null ;then

   	if ! dpkg-query -l |grep -w expect &>/dev/null ;then
		sudo apt-get install -y expect
	fi
	
else

	if ! rpm -qa |grep -w expect &>/dev/null ;then
	sudo yum install -y expect
	fi

fi 

for i in $hosts
do
echo "...............$i.................."
echo "Upload files  ${file_name} to $i"
expect <<EOF

	spawn  scp -P$sshport  -rp ${file_name}   $user@$i:/$user
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
echo "Run script ${file_name} on $k"
expect <<EOF

	spawn  ssh -p$sshport  $user@$k   "test -f  /root/${file_name}  && sh /root/${file_name} kunlun /home/kunlun/klustron"
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF
done 





