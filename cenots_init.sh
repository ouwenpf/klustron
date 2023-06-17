#!/bin/bash

#klunstron_user=${1:-kunlun}
#klunstron_basedir=${2:-/home/kunlun/klustron}
klunstron_user=$1
klunstron_basedir=$2

if [[  -f /etc/rc.d/init.d/functions ]];then
	. /etc/rc.d/init.d/functions

else 
	yum install -y initscripts  &>/dev/null   &\
	. /etc/rc.d/init.d/functions
    # success failure
	
fi 


if [ $# -ne 2 ];then
	action "Usage:  please input klunstron_user and klunstron_basedir" /bin/false
	exit 
fi

if ! id $klunstron_user &>/dev/null;then 
	#groupadd -g 1007 $klunstron_user 
    #useradd  -u 1007 -g 1007 $klunstron_user
	useradd  $klunstron_user  &>/dev/null   &&\
	echo 'kunlun#'|passwd  --stdin $klunstron_user &>/dev/null &&\
    sed -ri '/Allow root to run any commands anywhere/a '${klunstron_user}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers
	if [[ $? == 0 ]];then
		action "$1 User created successfully"  /bin/true
	else
		action "$1 User created failed"  /bin/false
	fi 
fi




yum remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
	action "postfix mariadb-libs Uninstallation successful"  /bin/true
else
	action "postfix mariadb-libsr Uninstallation failed"  /bin/false
fi 


yum install -y python git wget yum-utils sysvinit-tools libaio libaio-devel expect chrony python3-3.6.8-18.el7.x86_64 &>/dev/null
if [[ $? == 0 ]];then
	action "Basic package installation successful"  /bin/true
else
	action "Basic package installation  failed"  /bin/false
fi 



#for i in python git wget yum-utils sysvinit-tools libaio libaio-devel expect chrony python3-3.6.8-18.el7.x86_64
#do
#	if ! rpm -qa|grep  -w $i &>/dev/null;then
#	yum install -y $i  &>/dev/null
#	fi 
#done


if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	timedatectl set-timezone Asia/Shanghai
	if [[ $? == 0 ]];then
		action "Time zone configuration successful"  /bin/true
	else
		action "Time zone configuration  failed"  /bin/false
	fi 
else 
	action  "The time zone has been successfully configured" /bin/true
	
fi

if [[ -f  /etc/selinux/config ]];then
	setenforce 0 &&\
	sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	if [[ $? == 0 ]];then
		action "SELINUX configuration successful"  /bin/true
	else
		action "SELINUX configuration  failed"  /bin/false
	fi 
else 
	action "SELINUX No configuration because not installed"  /bin/true
fi

if [[ -f  /etc/security/limits.conf ]];then
cat >> /etc/security/limits.conf << EOF
*                soft    core          unlimited
*                hard    core          unlimited
*                soft    nproc         1000000
*                hard    nproc         1000000
*                soft    nofile        100000
*                hard    nofile        100000
*                soft    memlock       32000
*                hard    memlock       32000
*                soft    msgqueue      8192000
*                hard    msgqueue      8192000
EOF
	if [[ $? == 0 ]];then
		action "limits configuration successful"  /bin/true
	else
		action "limits configuration  failed"  /bin/false
	fi 

fi


 
systemctl stop firewalld &>/dev/null && systemctl disable firewalld   &>/dev/null
if [[ $? == 0 ]];then
	action "The firewall has been closed successful"  /bin/true
else
	action "The firewall has been closed  failed"  /bin/true
fi 

systemctl enable chronyd && systemctl start chronyd &>/dev/null

if [[ $? == 0 ]];then
	action "Time synchronization server successful"  /bin/true
else
	action "Time synchronization server  failed"  /bin/false
fi 



if [[ ! -d  $klunstron_basedir ]];then

	mkdir -p $klunstron_basedir  && chown -R $klunstron_user:$klunstron_user $klunstron_basedir  &>/dev/null
	if [[ $? == 0 ]];then
		action "Database directory creation successful"  /bin/true
	else
		action "Database directory creation  failed"  /bin/false
	fi 

fi