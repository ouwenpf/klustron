#!/bin/bash

#klunstron_user=${1:-kunlun}
#klunstron_basedir=${2:-/home/kunlun/klustron}
klunstron_user=$1
klunstron_basedir=$2

if ! [ `ping 8.8.8.8 -c 3 | grep "min/avg/max" -c` = '1' ]; then

		echo "No network"  
		exit

fi 




if [ $# -ne 2 ];then
	echo  "Usage:  please input klunstron_user and klunstron_basedir" 
	exit 
fi

if ! id $klunstron_user &>/dev/null;then 
	#groupadd -g 1007 $klunstron_user 
    #useradd  -u 1007 -g 1007 $klunstron_user
	sudo useradd -r -m -s /bin/bash  $klunstron_user  &>/dev/null   &&\
	sudo echo -e "kunlun#\nkunlun#"|sudo passwd $klunstron_user &>/dev/null &&\
    sudo sed -ri '/Members of the admin group may gain root privileges/i '${klunstron_user}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers
	if [[ $? == 0 ]];then
		echo  "$1 User created successfully" 
	else
		echo  "$1 User created failed"  
	fi 
fi




sudo apt-get remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
	echo  "postfix mariadb-libs Uninstallation successful"  
else
	echo  "postfix mariadb-libsr Uninstallation failed"  
fi 

:<<EOF
sudo apt-get update
sudo apt-get install -y git cmake libicu-dev libaio-dev libreadline-dev zlib1g-dev flex bison libssl-dev libcrypt-dev gcc g++ pkg-config python-dev unzip chrony
if [[ $? == 0 ]];then
	echo  "Basic package installation successful"  
else
	echo  "Basic package installation  failed"  
fi 
EOF



if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	sudo timedatectl set-timezone Asia/Shanghai
	if [[ $? == 0 ]];then
		echo  "Time zone configuration successful"  
	else
		echo  "Time zone configuration  failed"       
	fi 
else 
	echo   "The time zone has been successfully configured"      
	
fi

if [[ -f  /etc/selinux/config ]];then
	sudo setenforce 0 &&\
	sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	if [[ $? == 0 ]];then
		echo  "SELINUX configuration successful"       
	else
		echo  "SELINUX configuration  failed"       
	fi 
else 
	echo  "SELINUX No configuration because not installed"       
fi

if [[ -f  /etc/security/limits.conf ]];then
sudo bash -c "cat >> /etc/security/limits.conf" << EOF
*                soft    core          unlimited
*                hard    core          unlimited
*                soft    nproc         1000000
*                hard    nproc         1000000
*                soft    nofile        200000
*                hard    nofile        200000
*                soft    memlock       32000
*                hard    memlock       32000
*                soft    msgqueue      8192000
*                hard    msgqueue      8192000
EOF
	if [[ $? == 0 ]];then
		echo  "limits configuration successful"       
	else
		echo  "limits configuration  failed"       
	fi 

fi


 
sudo ufw disable &>/dev/null 
if [[ $? == 0 ]];then
	echo  "The firewall has been closed successful"       
else
	echo  "The firewall has been closed  failed"       
fi 



if [[ ! -d  $klunstron_basedir ]];then

	sudo mkdir -p $klunstron_basedir  && sudo chown -R $klunstron_user:$klunstron_user $klunstron_basedir  &>/dev/null
	if [[ $? == 0 ]];then
		echo  "Database directory creation successful"       
	else
		echo  "Database directory creation  failed"       
	fi 

fi