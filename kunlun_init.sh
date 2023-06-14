#!/bin/bash

klunstron_user=${1:-kunlun}
klunstron_basedir=${2:-/home/kunlun/klustron}

for i in python git wget yum-utils sysvinit-tools libaio libaio-devel expect chrony
do
	if ! rpm -qa|grep  -w $i &>/dev/null;then
	yum install -y $i  &>/dev/null
	fi 
done


if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	timedatectl set-timezone Asia/Shanghai
fi

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


yum remove  -y  postfix mariadb-libs 
setenforce 0
sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
systemctl enable chronyd
systemctl start chronyd
#groupadd -g 1007 $klunstron_user 
#useradd  -u 1007 -g 1007 $klunstron_user
useradd  $klunstron_user
echo 'kunlun#'|passwd  --stdin $klunstron_user
sed -ri '/Allow root to run any commands anywhere/a '${klunstron_user}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers
mkdir -p $klunstron_basedir
chown -R $klunstron_user:$klunstron_user $klunstron_basedir

