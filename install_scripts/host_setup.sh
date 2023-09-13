#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
klustron_VERSION=1.2.1
klustron_user=$1
klustron_basedir=$2
passwd='3G7NtoxW3NQql2ec'

if ! nc -z  www.kunlunbase.com  80  &>/dev/null; then
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit

elif [ $# -ne 2 ];then
  echo  -e "$COL_START${RED}Usage:  please input klustron_user and klustron_basedir$COL_END"
	exit 
fi









init_centos(){





if ! id $klustron_user &>/dev/null;then 
	#groupadd -g 1007 $klustron_user 
  #useradd  -u 1007 -g 1007 $klustron_user
	sudo useradd  $klustron_user  &>/dev/null   &&\
	echo "$passwd"|sudo passwd  --stdin $klustron_user &>/dev/null 
 
	if [[ $? == 0 ]];then
   if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
     sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
       if [[ $? == 0 ]];then
         echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
       fi
   fi
   
  else
    echo  -e "$COL_START${RED}$1 User created failed $USER不是root用户或没有具有root权限$COL_END"
    exit
 fi

else
  if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
    sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
    if [[ $? == 0 ]];then
      echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
    fi
  fi
     
 
fi



if [[ ! -d  $klustron_basedir ]];then

	sudo mkdir -p $klustron_basedir &>/dev/null  && sudo chown -R $klustron_user:$klustron_user $klustron_basedir  &>/dev/null
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}Database directory creation successful$COL_END"
	else
   echo  -e "$COL_START${RED}Database directory creation  failed$COL_END"
   exit
	fi 

fi



sudo yum remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
 echo  -e "$COL_START${GREEN}postfix mariadb-libs Uninstallation successful$COL_END"
else
  echo  -e "$COL_START${GREEN}postfix mariadb-libsr No installation present, no need for uninstallation$COL_END"
fi 




<<!
if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	timedatectl set-timezone Asia/Shanghai
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}Time zone configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}Time zone configuration  failed$COL_END"
	fi 
else 
  echo  -e "$COL_START${GREEN}The time zone has been successfully configured$COL_END"
fi

!

if [[ -f  /etc/selinux/config ]];then
	sudo setenforce 0 &>/dev/null &&\
	sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   &>/dev/null
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}SELINUX configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}SELINUX configuration  failed$COL_END"
	fi 
else 
  echo  -e "$COL_START${GREEN}SELINUX No configuration because not installed$COL_END"
	
fi


if [[ -f  /etc/security/limits.conf ]];then
  if ! egrep -iq '*^.*hard.*200000$'  /etc/security/limits.conf;then
  
sudo cat >> /etc/security/limits.conf << EOF
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
  fi
  
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}limits configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}limits configuration  failed$COL_END"
		
	fi  

fi


 
sudo systemctl stop firewalld &>/dev/null && sudo systemctl disable firewalld   &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}The firewall has been closed successful$COL_END"
	
else
  echo  -e "$COL_START${GREEN}The firewall has been closed$COL_END"

fi 


if sudo systemctl enable chronyd &>/dev/null  && sudo systemctl start chronyd &>/dev/null;then
  echo  -e "$COL_START${GREEN}Time synchronization server successful$COL_END"
else
  sudo yum install chrony -y  &>/dev/null && sudo systemctl start chronyd &>/dev/null && sudo systemctl enable chronyd &>/dev/null
  if [[ $? == 0 ]];then
    echo  -e "$COL_START${GREEN}Time synchronization server successful$COL_END"
  else
    echo  -e "$COL_START${RED}Time synchronization server  failed$COL_END"
  fi
fi 



sudo yum install -y  python git wget yum-utils sysvinit-tools libaio libaio-devel expect  python3 jq figlet e2fsprogs-devel uuid-devel libuuid-devel   --skip-broken  &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}Basic package installation successful$COL_END"
	
else
  echo  -e "$COL_START${RED}Basic package installation  failed$COL_END"
	
fi 







if [[ -f /tmp/docker.log ]];then
  if ! sudo docker info 2>/dev/null|grep -iwq running;then
    if ! command -v docker &>/dev/null;then
      sudo yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo &>/dev/null &&\
      sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin device-mapper-persistent-data lvm2   &>/dev/null &&\
      sudo systemctl start docker.service
      
      if [[ $? -eq 0 ]];then
        echo  -e "$COL_START${GREEN}docker start successful$COL_END"
	      sudo  rm  -f /tmp/docker.log  &>/dev/null
      else
        echo  -e "$COL_START${RED}docker start or install failed$COL_END"
     	  sudo  rm  -f /tmp/docker.log  &>/dev/null
         
      fi
      
      
    else
      sudo systemctl start docker.service &>/dev/null 
      if [[ $? -eq 0 ]];then
        echo  -e "$COL_START${GREEN}docker start successful$COL_END"
	      sudo  rm  -f /tmp/docker.log   &>/dev/null
      else
        echo  -e "$COL_START${RED}docker start failed$COL_END"
	      sudo  rm  -f /tmp/docker.log  &>/dev/null
         
      fi
    
    fi
      
  
  fi

  
fi




}





init_ubuntu(){



if ! id $klustron_user &>/dev/null;then 
	#groupadd -g 1007 $klustron_user 
  #useradd  -u 1007 -g 1007 $klustron_user
	sudo useradd -r -m -s /bin/bash  $klustron_user  &>/dev/null   &&\
	sudo echo -e "$passwd\n$passwd"|sudo passwd $klustron_user &>/dev/null  
 
	if [[ $? == 0 ]];then
   if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
     sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
       if [[ $? == 0 ]];then
         echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
       fi
   fi
   
  else
    echo  -e "$COL_START${RED}$1 User created failed $USER不是root用户或没有具有root权限$COL_END"
    exit
 fi

else
  if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
    sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
    if [[ $? == 0 ]];then
      echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
    fi
  fi
     
 
fi





if [[ ! -d  $klustron_basedir ]];then

	sudo mkdir -p $klustron_basedir &>/dev/null  && sudo chown -R $klustron_user:$klustron_user $klustron_basedir  &>/dev/null
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}Database directory creation successful$COL_END"
	else
   echo  -e "$COL_START${RED}Database directory creation  failed$COL_END"
   exit
	fi 

fi




sudo apt-get remove  -y  postfix mariadb-libs  &>/dev/null
if [[ $? == 0 ]];then
 echo  -e "$COL_START${GREEN}postfix mariadb-libs Uninstallation successful$COL_END"
else
  echo  -e "$COL_START${GREEN}postfix mariadb-libsr No installation present, no need for uninstallation$COL_END"
fi 


<<!
if [ `timedatectl|grep -c 'Asia/Shanghai'` -eq 0 ];then
	timedatectl set-timezone Asia/Shanghai
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}Time zone configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}Time zone configuration  failed$COL_END"
	fi 
else 
  echo  -e "$COL_START${GREEN}The time zone has been successfully configured$COL_END"
fi

!

if [[ -f  /etc/selinux/config ]];then
	sudo setenforce 0 &&\
	sudo sed -ri  's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config   &>/dev/null
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}SELINUX configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}SELINUX configuration  failed$COL_END"
	fi 
else 
  echo  -e "$COL_START${GREEN}SELINUX No configuration because not installed$COL_END"
	
fi




if [[ -f  /etc/security/limits.conf ]];then
  if ! egrep -iq '*^.*hard.*200000$'  /etc/security/limits.conf;then
  
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
  fi
  
	if [[ $? == 0 ]];then
   echo  -e "$COL_START${GREEN}limits configuration successful$COL_END"
	else
   echo  -e "$COL_START${RED}limits configuration  failed$COL_END"
		
	fi 

fi




sudo ufw disable &>/dev/null &&  sudo systemctl disable ufw &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}The firewall has been closed successful$COL_END"
	
else
  echo  -e "$COL_START${GREEN}The firewall has been closed$COL_END"

fi 




if sudo systemctl enable chronyd &>/dev/null  && sudo systemctl start chronyd &>/dev/null;then
  echo  -e "$COL_START${GREEN}Time synchronization server successful$COL_END"
else
  sudo apt-get install chrony  -y  &>/dev/null && sudo systemctl start chrony &>/dev/null && sudo systemctl enable chrony &>/dev/null
  if [[ $? == 0 ]];then
    echo  -e "$COL_START${GREEN}Time synchronization server successful$COL_END"
  else
    echo  -e "$COL_START${RED}Time synchronization server  failed$COL_END"
  fi
fi 




sudo bash -c 'echo "deb http://archive.ubuntu.com/ubuntu/ xenial-updates main restricted" >> /etc/apt/sources.list' &>/dev/null &&\
sudo apt-get update &>/dev/null &&\
sudo apt-get install -y git apt-utils libicu-dev  libreadline-dev zlib1g-dev flex bison libssl-dev libcrypt-dev gcc g++ pkg-config python2 python2-dev libncurses5  locales python-setuptools unzip chrony expect jq figlet  curl lsb-release gnupg gnupg-l10n gnupg-utils net-tools iputils-ping sshpass e2fsprogs  uuid-dev libossp-uuid-dev &>/dev/null
if [[ $? == 0 ]];then
  echo  -e "$COL_START${GREEN}Basic package installation successful$COL_END"
	
else
  echo  -e "$COL_START${RED}Basic package installation  failed$COL_END"
	
fi 




if [[ -s /tmp/docker.log ]];then
  if ! sudo docker info 2>/dev/null|grep -iwq running;then
    if ! command -v docker &>/dev/null;then
      sudo apt-get  install -y docker.io &>/dev/null &&\
      sudo systemctl start docker.service &>/dev/null
      if [[ $? -eq 0 ]];then
        echo  -e "$COL_START${GREEN}docker start successful$COL_END"
	sudo  rm  -f /tmp/docker.log  &>/dev/null
      else
        echo  -e "$COL_START${RED}docker start or install failed$COL_END"
	sudo  rm  -f /tmp/docker.log  &>/dev/null
         
      fi
      
      
    else
      sudo systemctl start docker.service &>/dev/null 
      if [[ $? -eq 0 ]];then
        echo  -e "$COL_START${GREEN}docker start successful$COL_END"
	sudo  rm  -f /tmp/docker.log  &>/dev/null
      else
        echo  -e "$COL_START${RED}docker start failed$COL_END"
	sudo  rm  -f /tmp/docker.log  &>/dev/null
        
      fi
    
    fi
      
  
  fi

  
fi




}










  
if [ -f "/etc/os-release" ]; then
  source /etc/os-release
  echo  -e "$COL_START${GREEN}正在安装必要的软件包$COL_END"
    if [[ "$ID" == "ubuntu" ]]; then
      echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
      
      init_ubuntu 
    elif [[ "$ID" == "centos" ]]; then
      echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
      
      init_centos  
    else
      echo  -e "$COL_START$RED未知系统$COL_END"
      exit
    fi
  
else
  echo "os-release文件不存,未知系统"
  exit
fi




