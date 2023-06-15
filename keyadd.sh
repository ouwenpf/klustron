#!/bin/bash

user=$1
passwd=$2
sshport=$3
shift 3
hosts=$*

if [ $user == "root" ];then
		echo "Currently root user, unable to execute,Please switch to Kunlun user execution"
		exit 

fi

if [ $# -lt 1 ];then
	echo "Usage:  user passwd port ip_list......"
	exit 
fi


echo "start ..... "
#hosts="192.168.0.129 192.168.0.134 192.168.0.125"
#passwd='kunlun#'


if ! rpm -qa |grep -w expect &>/dev/null ;then
	sudo yum install -y expect
fi

ssh-keygen -t rsa -N '' -f $HOME/.ssh/id_rsa -q
#cat  $HOME/.ssh/id_rsa.pub  > $HOME/.ssh/authorized_keys 
#chmod 600 $HOME/.ssh/authorized_keys 





for i in $hosts
do
echo "...............$i.................."
echo ''  $HOME/.ssh/known_hosts &>/dev/null
expect <<EOF

	spawn ssh-copy-id -f -p$sshport $user@$i
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
echo ''  $HOME/.ssh/known_hosts &>/dev/null
expect <<EOF

	spawn  scp -P$sshport  -rp $HOME/.ssh/id_rsa  $HOME/.ssh/id_rsa.pub   $user@$k:/home/$user/.ssh 
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF
done 




datefile=$(date +%Y%m%d%H%M%S).log

for j in $hosts
do
ssh -p$sshport $user@$j  echo $(date +%Y%m%d%H%M%S)   >> $datefile


done

if [ $((`tail -1 $datefile`-`head -1 $datefile`)) -le 1 ];then
        echo 'Same server time'
		rm -f $datefile &>/dev/null
else
        echo 'Attention: Please check if the server time is consistent. If not, please make sure to set the time properly'



fi


