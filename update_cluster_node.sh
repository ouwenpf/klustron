#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
config_json=$1
VERSION=1.2.1

if [[ ! -s $config_json ]]  ||  [[ $# -ne 1 ]]; then
	echo -e "$COL_START${RED}Usage $0 args file_json $COL_END"
  exit

elif ! jq  '.'  $config_json &>/dev/null;then
  echo -e "$COL_START$RED$config_json syntax error$COL_END"
  exit 

elif ! ping -c3 8.8.8.8  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit

elif [[ $(echo `pwd`|grep 'cloudnative/cluster$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster目录下 $COL_END"
	exit 

  
elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中不存在用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  


elif ! command -v jq &>/dev/null  ;then
  echo  -e "$COL_START$RED正在下载jq命令 $COL_END"
  
  if [ -f "/etc/os-release" ]; then
    source /etc/os-release
    
      if [[ "$ID" == "ubuntu" ]]; then
        echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        sudo apt-get install -y jq &&  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
        
      elif [[ "$ID" == "centos" ]]; then
        echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        sudo yum install -y jq  &>/dev/null  &&  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
        
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit

      fi
    
  else
      echo "os-release文件不存,未知系统"
	    exit
  fi
  
else
	ip_list=($(jq  '.machines[].ip'  $config_json |xargs))
	user_list=($(jq  '.machines[].user'  $config_json |xargs))
	basedir_list=($(jq  '.machines[].basedir'  $config_json |xargs))
	sshport_list=($(jq  '.machines[].sshport'  $config_json |xargs))
	
	
	echo ${ip_list[*]}
	echo ${user_list[*]}
	echo ${basedir_list[*]}
  echo ${sshport_list[*]}
	
fi



download_software(){

if [[ -d clustermgr ]];then
	cd  clustermgr &&\
	rm -f kunlun-cluster-manager-$VERSION.tgz kunlun-node-manager-$VERSION.tgz
	cd - 
else 
	echo -e "$COL_TTART${RED}clustermgr:No such file or directory$COL_END"
	exit 

fi


if nc -z 192.168.0.104  14000 ;then
	python2 setup_cluster_manager.py --action=download --downloadsite=internal --downloadtype=daily_rel --product_version=$VERSION

else
	python2 setup_cluster_manager.py --action=download --downloadsite=devsite  --downloadtype=daily_rel --product_version=$VERSION
fi





if [[ -s clustermgr/kunlun-cluster-manager-$VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-cluster-manager-$VERSION.tgz 
else
	
   echo -e "$COL_START${RED}请检查kunlun-cluster-manager-$VERSION.tgz文件是否完整和存在$COL_END"
   exit
	
fi


if [[ -s clustermgr/kunlun-node-manager-$VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-node-manager-$VERSION.tgz 
else
	
   echo -e "$COL_START${RED}请检查kunlun-node-manager-$VERSION.tgz文件是否完整和存在$COL_END"
   exit
	
fi



}



restart_cluster_mgr(){

	echo -e "$COL_START${RED}restart_cluster_mgr...$COL_END"
  #download_software
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
	for i in $(seq 0 $((${#ip_list[*]}-1)))
	do
    if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
	    
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -d ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION";then
      for j in `seq 1 30`
      do
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps xua | grep cluster_mgr | grep -v grep | awk '\''{print "kill -9",$2}'\'' | bash' 
      done
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/bin && ./start_cluster_mgr.sh" &>/dev/null
        if [[ $? -eq 0 ]];then
          echo -e "$COL_START${GREEN}${ip_list[$i]}主机cluster_mgr重启成功$COL_END"
        else
          echo -e "$COL_START${GREEN}${ip_list[$i]}主机cluster_mgr重启失败$COL_END"
        fi
    fi
	done



}











restart_node_mgr(){

 echo -e "$COL_START${RED}restart_node_mgr...$COL_END"
  #download_software
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
	for i in $(seq 0 $((${#ip_list[*]}-1)))
	do
    if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
	    
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -d ${basedir_list[$i]}/kunlun-node-manager-$VERSION";then
      for j in `seq 1 30`
      do
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps xua | grep node_mgr | grep -v grep | awk '\''{print "kill -9",$2}'\'' | bash' 
      done
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-node-manager-$VERSION/bin && ./start_node_mgr.sh" &>/dev/null
        if [[ $? -eq 0 ]];then
          echo -e "$COL_START${GREEN}${ip_list[$i]}主机node_mgr重启成功$COL_END"
        else
          echo -e "$COL_START${GREEN}${ip_list[$i]}主机node_mgr重启失败$COL_END"
        fi
    fi
	done






}













echo -e "\e[31m 
Welcome to the Klusteron component update system
----------------------------------------------------- \e[0m\e[32m 
1. restart_cluster_mgr

2. restart_node_mgr
 
3. 

4. 

5. restart node_mgr &&  cluster_mgr   \e[0m\e[31m 
------------------------------------------------------\e[0m"

read  -t 300 -p "请输入操作序号: "   oper_id

case $oper_id in 
1)
  restart_cluster_mgr
	;;
	
2)
	restart_node_mgr
	;;

*) 
	echo "请输入正确的更新序号"
	;;



esac

