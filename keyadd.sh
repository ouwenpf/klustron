#!/bin/bash

sshport=${1:-22}
passwd=$2
shift 2
hosts=$*

if [ $USER == "root" ];then
		echo "Currently root user, unable to execute"
		exit 

fi

if [ $# -lt 1 ];then
	echo "Usage:  port passwd ip_list......"
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
echo "...............$host.................."
echo ''  $HOME/.ssh/known_hosts &>/dev/null
expect <<EOF

	spawn ssh-copy-id -f -p$sshport $USER@$i
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF
done 





for k in $hosts
do
echo "...............$host.................."
echo ''  $HOME/.ssh/known_hosts &>/dev/null
expect <<EOF

	spawn  scp -P$sshport  -rp $HOME/.ssh/id_rsa  $HOME/.ssh/id_rsa.pub   $USER@$k:$HOME/.ssh 
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
ssh -p$sshport $j  echo $(date +%Y%m%d%H%M%S)   >> $datefile


done

if [ $((`tail -1 $datefile`-`head -1 $datefile`)) -le 1 ];then
        echo 'Same server time'
		rm -f $datefile &>/dev/null
else
        echo 'Attention: Please check if the server time is consistent. If not, please make sure to set the time properly'



fi


