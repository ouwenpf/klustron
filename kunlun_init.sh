#!/bin/bash

klunstron_user=${1:-kunlun}
klunstron_basedir=${2:-/kunlun}

for i in python git wget yum-utils sysvinit-tools libaio libaio-devel expect chrony
do
	if ! rpm -qa|grep  -w $i &>/dev/null;then
	yum install -y $i  &>/dev/null
	fi 
done


if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	timedatectl set-timezone Asia/Shanghai
fi

echo "*                -       nofile          200000" >>/etc/security/limits.conf
echo "*                -       nproc           65535" >>/etc/security/limits.conf
yum remove  -y  postfix mariadb-libs 
systemctl stop firewalld
systemctl disable firewalld
systemctl enable chronyd
systemctl start chronyd
groupadd -g 1008 $klunstron_user 
useradd  -u 1007 -g 1008 $klunstron_user
echo 'kunlun#'|passwd  --stdin $klunstron_user
sed -ri '/Allow root to run any commands anywhere/a '${klunstron_user}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers
mkdir -p $klunstron_basedir
chown -R $klunstron_user:$klunstron_user $klunstron_basedir

