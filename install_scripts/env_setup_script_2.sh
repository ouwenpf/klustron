#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
klustron_VERSION=1.2.1
passwd='3G7NtoxW3NQql2ec'
klustron_key=$(pwd)

custom_json='custom.json'
config_json='../klustron_config.json'
control_machines=($(jq  '.user,.password,.sshport'  $custom_json|xargs))
machines_list=($(jq '.machines[].ip' $custom_json|xargs))
host_setup='host_setup.sh'

#获取kunlun用户,目录,IP等信息
klustron_user=$(jq  '.machines[].user'  $config_json|sort|uniq|xargs)
klustron_basedir=$(jq  '.machines[].basedir'  $config_json|sort|uniq|xargs)
klustron_xpanel_list=$(jq  '.xpanel.ip'  $config_json |xargs)
klustron_xpanel_port=$(jq  '.xpanel.port'  $config_json |xargs)


if [[ ! -s  $custom_json ]] ;then
  echo  -e "$COL_START${RED}当前目录下不存在$custom_json配置文件$COL_END" 
  exit
  
elif [[ ! -s  $config_json ]] ;then
  echo  -e "$COL_START${RED}上级目录不存在$config_json配置文件$COL_END" 
  exit

elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit
elif ! jq  '.'  custom.json &>/dev/null;then
  echo -e "$COL_START$RED$custom_json syntax error$COL_END"
  exit 

elif [[ $(echo `pwd`|grep 'cloudnative/cluster/install_scripts$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster/install_scripts目录下 $COL_END"
	exit 
 
<<!
elif [[ ${control_machines[0]} != "$USER" ]];then
  echo -e "$COL_START$RED $custom_json中没有设置用户:$USER请到对应的用户下执行脚本$0$COL_END"
  exit
!

fi  







# 控制机上面创建kunlun用户,以便后续切换此用户安装集群

if [ -f "/etc/os-release" ]; then
  source /etc/os-release
  #echo  -e "$COL_START${GREEN}正在控制机上创建用户名$COL_END"
  
  
  
    if [[ "$ID" == "ubuntu" ]]; then
      #echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        
        
        if ! id $klustron_user &>/dev/null;then 
	        #groupadd -g 1007 $klustron_user 
          #useradd  -u 1007 -g 1007 $klustron_user
	        sudo useradd -r -m -s /bin/bash  $klustron_user  &>/dev/null   &&\
	        sudo echo -e "$passwd\n$passwd"|sudo passwd $klustron_user &>/dev/null       
  
	          if [[ $? == 0 ]];then
             if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
                 if [[ $? == 0 ]];then
                   echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
                 fi
             fi
   
            else
              echo  -e "$COL_START${RED}$klustron_user User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
            fi
           

        else
          if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
            echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
            fi
          fi
     
 
        fi





      
      
      
      elif [[ "$ID" == "centos" ]]; then
        #echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        
      
          if ! id $klustron_user &>/dev/null;then 
  	        #groupadd -g 1007 $klustron_user 
            #useradd  -u 1007 -g 1007 $klustron_user
  	        sudo useradd  $klustron_user  &>/dev/null   &&\
  	        echo "$passwd"|sudo passwd  --stdin $klustron_user &>/dev/null 
   
  	        if [[ $? == 0 ]];then
                   
             if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               suod sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
               if [[ $? == 0 ]];then
                 echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
               else 
                 echo  -e "$COL_START${RED}$klustron_user权限配置失败(sudoers)$COL_END"
                 exit
               fi
             fi
     
            else
              echo  -e "$COL_START${RED}$klustron_user User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
              exit
            fi
  
         else
          if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sudo sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
              echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
            else
              echo  -e "$COL_START${RED}$klustron_user权限配置失败(sudoers)$COL_END"
              exit
            fi
          fi
       
   
        fi      
        
      
      
      
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit
      fi
  
else
  echo "os-release文件不存,未知系统"
  exit
fi







if id $klustron_user &>/dev/null;then
  cd ../../.. &&\
  sudo chown -R $klustron_user:$klustron_user cloudnative &>/dev/null &&\
  cd -  &>/dev/null
    if [[ $? -ne 0 ]];then
      echo -e "$COL_START${RED}控制机上cloudnative目录权限设置失败$COL_END"
      exit
    fi
else
  echo -e "$COL_START${RED}控制机$klustron_user用户不存在$COL_END"
  exit
fi



