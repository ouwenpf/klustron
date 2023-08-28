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
  
elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
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
  

elif ! jq  '.'  $config_json &>/dev/null;then
  echo -e "$COL_START$RED$config_json syntax error$COL_END"
  exit 

elif [[ $(echo `pwd`|grep 'cloudnative/cluster$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster目录下 $COL_END"
	exit 

elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中没有设置用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  


else
	ip_list=($(jq  '.machines[].ip'  $config_json |xargs))
	user_list=($(jq  '.machines[].user'  $config_json |xargs))
	basedir_list=($(jq  '.machines[].basedir'  $config_json |xargs))
	sshport_list=($(jq  '.machines[].sshport'  $config_json |xargs))
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
  

fi



download_software(){

if [[ $oper_id == 3 ]];then

  if [[ -d clustermgr ]];then
	  cd  clustermgr &>/dev/null &&\
	  rm -f kunlun-cluster-manager-$VERSION.tgz &>/dev/null &&\
	  cd -  &>/dev/null
  else 
	  echo -e "$COL_START${RED}clustermgr:No such file or directory$COL_END"
	  exit 
  fi
elif [[ $oper_id == 4 ]];then

  if [[ -d clustermgr ]];then
	  cd  clustermgr &>/dev/null &&\
	  rm -f kunlun-node-manager-$VERSION.tgz &>/dev/null &&\
	  cd -  &>/dev/null
  else 
	  echo -e "$COL_START${RED}clustermgr:No such file or directory$COL_END"
	  exit     
  fi

fi






if nc -z 192.168.0.104  14000 ;then
	python2 setup_cluster_manager.py --action=download --downloadsite=internal --downloadtype=daily_rel --product_version=$VERSION &>/dev/null
  if [[ $? -eq 0 ]];then
    echo -e "$COL_START${GREEN}更新包已经下载完毕,正准备更新$COL_END"
  else
    echo -e "$COL_START${RED}更新包已经下载有异常,更新终止$COL_END"
    exit
  fi
    

else
	python2 setup_cluster_manager.py --action=download --downloadsite=devsite  --downloadtype=daily_rel --product_version=$VERSION &>/dev/null
   if [[ $? -eq 0 ]];then
    echo -e "$COL_TTART${GREEN}更新包已经下载完毕,正准备更新$COL_END"
  else
    echo -e "$COL_TTART${RED}更新包已经下载有异常,更新终止$COL_END"
    exit
  fi
fi





if [[ -s clustermgr/kunlun-cluster-manager-$VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-cluster-manager-$VERSION.tgz && cd ../
else
	
   echo -e "$COL_START${RED}请检查kunlun-cluster-manager-$VERSION.tgz文件是否完整和存在$COL_END"
   exit
	
fi


if [[ -s clustermgr/kunlun-node-manager-$VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-node-manager-$VERSION.tgz && cd ../
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
 
    if ! nc -z  ${ip_list[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${ip_list[$i]}端口${sshport_list[$i]}有异常,无法连接,请检查网络$COL_END" 
      continue  
    fi
    
     if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
    
     
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-cluster-manager-*.service";then
      systemctl_cluster_mgr=$(ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]};ls kunlun-cluster-manager-*.service")
    fi
    

    
    

    



      # stop_cluster_mgr

      if  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then
        while true
        do
      
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl stop $systemctl_cluster_mgr &>/dev/null" 
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -v grep | awk '\''{print "kill -9", $2}'\''|bash' 
        
        
          if ! ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then
            break 
          fi
        
        done
      fi
        
      
    
      # start_cluster_mgr 
      #if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-cluster-manager-*.service";then
      if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/bin/start_cluster_mgr.sh";then
      while true
      do
        #ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/bin && ./start_cluster_mgr.sh" &>/dev/null
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl start $systemctl_cluster_mgr &>/dev/null" 
        
          if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then 
            echo -e "$COL_START${GREEN}${ip_list[$i]}主机cluster_mgr重启成功$COL_END"
            break 
          
          else
            let count_start_cluster_mgr++
            if [[ $count_start_cluster_mgr -eq 10 ]];then
              echo -e "$COL_START${RED}${ip_list[$i]}主机cluster_mgr重启失败,请检查${ip_list[$i]}主机上是否安装有cluster_mgr$COL_END"
              break
            fi
          fi 
        
        
      done
       
    fi
 
 
 
    
	done



}





update_cluster_mgr(){

	echo -e "$COL_START${RED}update_cluster_mgr...$COL_END"
  download_software
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
	for i in $(seq 0 $((${#ip_list[*]}-1)))
	do
 
    if ! nc -z  ${ip_list[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${ip_list[$i]}端口${sshport_list[$i]}有异常,无法连接,请检查网络$COL_END" 
      continue  
    fi
    
     if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
    
     
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-cluster-manager-*.service";then
      systemctl_cluster=$(ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]};ls kunlun-cluster-manager-*.service")
    fi
    
    
      # stop_cluster_mgr

      if  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then
        while true
        do
      
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl stop $systemctl_cluster &>/dev/null" 
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -v grep | awk '\''{print "kill -9", $2}'\''|bash' 
        
        
          if ! ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then
            break 
          fi
        
        done
      fi
      
      
      
      
      

      
    
    
    # start_cluster_mgr   
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/bin/start_cluster_mgr.sh";then
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-cluster-manager-$VERSION.tgz ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]} &>/dev/null &&\
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-cluster-manager-$VERSION/bin ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/  &>/dev/null  &&\
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-cluster-manager-$VERSION/build.info ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/  &>/dev/null 
    
      while true
      do
        #ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-cluster-manager-$VERSION/bin && ./start_cluster_mgr.sh" &>/dev/null
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl start $systemctl_cluster &>/dev/null" 
        
          if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-cluster-manager-'"$VERSION"'" | grep -vq grep' ;then 
            echo -e "$COL_START${GREEN}${ip_list[$i]}主机cluster_mgr更新成功$COL_END"
            break 
          
          else
            let count_start_cluster_mgr++
            if [[ $count_start_cluster_mgr -eq 10 ]];then
              echo -e "$COL_START${RED}${ip_list[$i]}主机cluster_mgr更新失败,请检查${ip_list[$i]}主机上是否安装有cluster_mgr$COL_END"
              break
            fi
          fi 
        
        
      done
           
   fi  
        
          
        
	done



}









restart_node_mgr(){

	echo -e "$COL_START${RED}restart_node_mgr...$COL_END"
  #download_software
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
 
	for i in $(seq 0 $((${#ip_list[*]}-1)))
	do
 
    if ! nc -z  ${ip_list[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${ip_list[$i]}端口${sshport_list[$i]}有异常,无法连接,请检查网络$COL_END" 
      continue  
    fi
    
     if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
    
     
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-*.service";then
      systemctl_node_mgr=$(ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]};ls kunlun-node-manager-*.service")
    fi
    

    
    

    



      # stop_node_mgr

      if  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then
        while true
        do
      
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl stop $systemctl_node_mgr &>/dev/null" 
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -v grep | awk '\''{print "kill -9", $2}'\''|bash' 
        
        
          if ! ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then
            break 
          fi
        
        done
      fi
        
      
    
      # start_node_mgr 
      #if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-*.service";then
      if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-$VERSION/bin/start_node_mgr.sh";then
      while true
      do
        #ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-node-manager-$VERSION/bin && ./start_node_mgr.sh" &>/dev/null
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl start $systemctl_node_mgr &>/dev/null" 
        
          if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then 
            echo -e "$COL_START${GREEN}${ip_list[$i]}主机node_mgr重启成功$COL_END"
            break 
          
          else
            let count_start_node_mgr++
            if [[ $count_start_node_mgr -eq 10 ]];then
              echo -e "$COL_START${RED}${ip_list[$i]}主机node_mgr重启失败,请检查${ip_list[$i]}主机上是否安装有node_mgr$COL_END"
              break
            fi
          fi 
        
        
      done
       
    fi
 
 
 
    
	done



}





update_node_mgr(){

	echo -e "$COL_START${RED}update_node_mgr...$COL_END"
  download_software
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
	for i in $(seq 0 $((${#ip_list[*]}-1)))
	do
 
    if ! nc -z  ${ip_list[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${ip_list[$i]}端口${sshport_list[$i]}有异常,无法连接,请检查网络$COL_END" 
      continue  
    fi
    
     if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
    
     
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-*.service";then
      systemctl_node_mgr=$(ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]};ls kunlun-node-manager-*.service")
    fi
    
    
      # stop_node_mgr

      if  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then
        while true
        do
      
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl stop $systemctl_node_mgr &>/dev/null" 
          ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -v grep | awk '\''{print "kill -9", $2}'\''|bash' 
        
        
          if ! ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then
            break 
          fi
        
        done
      fi
      
      
      
      
      

      
    
    
    # start_node_mgr   
    if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-$VERSION/bin/start_node_mgr.sh";then
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-node-manager-$VERSION.tgz ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]} &>/dev/null &&\
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-node-manager-$VERSION/bin ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]}/kunlun-node-manager-$VERSION/  &>/dev/null &&\
    scp -rp -P${sshport_list[$i]} clustermgr/kunlun-node-manager-$VERSION/build.info ${user_list[$i]}@${ip_list[$i]}:${basedir_list[$i]}/kunlun-node-manager-$VERSION/  &>/dev/null
    
      while true
      do
        #ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "cd ${basedir_list[$i]}/kunlun-node-manager-$VERSION/bin && ./start_node_mgr.sh" &>/dev/null
        ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "sudo systemctl start $systemctl_node_mgr &>/dev/null" 
        
          if ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} 'ps aux | grep -w "'"${basedir_list[$i]}"'/kunlun-node-manager-'"$VERSION"'" | grep -vq grep' ;then 
            echo -e "$COL_START${GREEN}${ip_list[$i]}主机node_mgr更新成功$COL_END"
            break 
          
          else
            let count_start_node_mgr++
            if [[ $count_start_node_mgr -eq 10 ]];then
              echo -e "$COL_START${RED}${ip_list[$i]}主机node_mgr更新失败,请检查${ip_list[$i]}主机上是否安装有node_mgr$COL_END"
              break
            fi
          fi 
        
        
      done
           
   fi  
        
          
        
	done



}




update_xpanel(){

	echo -e "$COL_START${RED}update_xpanel...$COL_END"
  install_script
 #VERSION=$(ls kunlun-node-manager-*gz|awk -F '-'  '{print $4}'|cut -c  1-5)
	for i in $(seq 0 $((${#xpanel_ip[*]}-1)))
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
 
 
    if [[ "${xpanel_port[$i]}" == "null" ]];then
      xpanel_ip[$i]=18080
    fi 
    
    
    
    if ! nc -z  ${xpanel_ip[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${xpanel_ip[$i]}:${sshport_list[$i]}有异常$COL_END" 
      continue  
    fi
    
   
   if ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "sudo docker info >/dev/null";then
       network_mode_list=($(ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "sudo docker network ls | egrep -v 'none|host' | awk '{print \$2}' | sed '1d' | sed 's#[[:space:]]##g' | awk '{print NR\".\"\$0}'"))
       install_xpanel=$(egrep -w "xpanel_${xpanel_port[$i]}" clustermgr/install.sh |awk -F ';' 'NR==1{print $2}'|awk -F '"' '{print $1}')
       install_xpanel_mdc=$(egrep -w "xpanel_${xpanel_port[$i]}" clustermgr/install.sh |awk -F ";" '{print $2}'|awk -F '"' '{print $1}'|sort -rn|uniq |sed 's#--restart=always#--network '$docker_network'  --restart=always#g')
    
       if [[ ${#network_mode_list[*]} -eq 1 ]];then
         ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "sudo docker container rm -f xpanel_${xpanel_port[$i]} &>/dev/null && sudo docker image rm -f registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:$VERSION &>/dev/null" &&\
         ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "$install_xpanel &>/dev/null"
         
          if [[ $? -eq 0 ]];then
            echo -e "$COL_START${GREEN}${xpanel_ip[$i]}主机:xpanel更新成功$COL_END"
          else
            echo -e "$COL_START${RED}${xpanel_ip[$i]}主机:xpanel更新失败$COL_END"
          fi

       else
         network_mode
       fi
       
       
   else
       echo -e "$COL_START${RED}docker服务有异常$COL_END" 
       continue
   fi
   
   
   
   
  done


}




install_script(){

for i in install clean start stop
do

if [[ "$mdc" == "null"  ]];then
  python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i  &>/dev/null
  xpanel_ip=($(jq  '.xpanel.ip'  $config_json |xargs))
  xpanel_port=($(jq  '.xpanel.port'  $config_json |xargs))

  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END" 
    exit
  fi

else
  python2 setup_cluster_manager.py --autostart --config=$config_json  --multipledc --product_version=$VERSION  --action=$i &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END"  
    exit
  else
    xpanel_ip=($(jq  '.xpanel.nodes[].ip'  $config_json |xargs))
    xpanel_port=($(jq  '.xpanel.nodes[].port'  $config_json |xargs))

  fi


fi

done

 
}


network_mode(){
echo -e "$COL_START${RED}Please select network mode$COL_END" 
echo -e "$COL_START${RED}-----------------------------------------------------$COL_END"
echo -e "$COL_START$GREEN ${network_mode_list[*]}$COL_END"|xargs -n1
echo -e "$COL_START${RED}-----------------------------------------------------$COL_END"



read  -t 300 -p "请输入操作序号: "   network_id


if [[ $network_id =~ ^[0-9]+$ ]] && [[ $network_id -le "${#network_mode_list[*]}" ]]; then
    docker_network=$(echo "${network_mode_list[$(($network_id-1))]}"|sed 's#^[0-9].##g')
    
    
    if [[ "$docker_network" == "bridge" ]];then
      ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "sudo docker container rm -f xpanel_${xpanel_port[$i]} &>/dev/null && sudo docker image rm -f registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:$VERSION &>/dev/null" &&\
      ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "$install_xpanel &>/dev/null"
      if [[ $? -eq 0 ]];then
        echo -e "$COL_START${GREEN}${xpanel_ip[$i]}主机:xpanel更新成功$COL_END"
      else
        echo -e "$COL_START${RED}${xpanel_ip[$i]}主机:xpanel更新失败$COL_END"
      fi
      
    else
      ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "sudo docker container rm -f xpanel_${xpanel_port[$i]} &>/dev/null && sudo docker image rm -f registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:$VERSION &>/dev/null" &&\
      ssh -p${sshport_list[$i]} ${user_list[$i]}@${xpanel_ip[$i]} "$install_xpanel_mdc &>/dev/null"
      if [[ $? -eq 0 ]];then
        echo -e "$COL_START${GREEN}${xpanel_ip[$i]}主机:xpanel更新成功$COL_END"
      else
        echo -e "$COL_START${RED}${xpanel_ip[$i]}主机:xpanel更新失败$COL_END"
      fi
    
    fi
    

    
    
else
    echo "请输入正确的网络模式"
    exit
fi







}




echo -e "\e[31m 
Welcome to the Klusteron component update system
----------------------------------------------------- \e[0m\e[32m 
1. restart_cluster_mgr

2. restart_node_mgr
 
3. update cluster_mgr

4. update node_mgr 
   
5. update_xpanel    \e[0m\e[31m 
------------------------------------------------------\e[0m"

read  -t 300 -p "请输入操作序号: "   oper_id

case $oper_id in 
1)
  restart_cluster_mgr
	;;
	
2)
	restart_node_mgr
	;;

3)
	update_cluster_mgr
	;;

4)
	update_node_mgr
	;;

5)
	update_xpanel
	;;

*) 
	echo "请输入正确的更新序号"
	;;



esac

