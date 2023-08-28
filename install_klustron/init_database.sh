#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
config_json=$1
user_passwd=($2 $3)
klustron_VERSION=1.2.1
init_file='init_klustron.sh'



if [[ ! -s $config_json ]]  ||  [[ $# -ne 1 ]]; then
	echo -e "$COL_START${RED}Usage $0 args file_json $COL_END"
  exit
  
  

elif ! jq  '.'  $config_json &>/dev/null;then
  echo -e "$COL_START$RED$config_json syntax error$COL_END"
  exit 
  

elif [[ $(echo `pwd`|grep 'cloudnative/cluster$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster目录下 $COL_END"
	exit 



elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中没有设置用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  




elif [[ $( jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|wc -l) -ne 1 ]];then
  echo  -e  "$COL_START$RED$config_json存在多个用户,请设置相同的用户,不设置默认为kunlun用户$COL_END"
  exit

elif [[ $( jq  '.machines[].sshport'  $config_json |sed 's/null/"22"/g'|sort -rn|uniq|wc -l) -ne 1 ]];then
  echo  -e  "$COL_START$RED$config_json存在多个ssh端口,请设置相同的sshd端口,不设置默认为22端口$COL_END"
  exit






else
	ip_list=($(jq  '.machines[].ip'  $config_json |xargs ))
	user_list=($(jq  '.machines[].user'  $config_json |xargs))
	basedir_list=($(jq  '.machines[].basedir'  $config_json |xargs))
	sshport_list=($(jq  '.machines[].sshport'  $config_json |xargs))
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
  control_user=$(jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort|uniq|xargs)

fi




if [[ "$mdc" == "null"  ]];then

  xpanel_ip=($(jq  '.xpanel.ip'  $config_json |xargs))
  xpanel_port=($(jq  '.xpanel.port'  $config_json |xargs))
  xpanel_sshport=($(jq  '.xpanel.sshport'  $config_json |xargs))
else
  xpanel_ip=($(jq  '.xpanel.nodes[].ip'  $config_json |xargs))
  xpanel_port=($(jq  '.xpanel.nodes[].port'  $config_json |xargs))
  xpanel_sshport=($(jq  '.xpanel.nodes[].sshport'  $config_json |xargs))

fi





#for klustron_clustre

download_software(){

echo -e "$COL_START${GREEN}正在下载Klustron数据库安装包,请勿中断........$COL_END" 

if [[ -d clustermgr ]];then
	cd  clustermgr &&\
  mv kunlun-cluster-manager-$klustron_VERSION.tgz kunlun-cluster-manager-$klustron_VERSION.tgz.bak  &>/dev/null &&\
  mv kunlun-node-manager-$klustron_VERSION.tgz kunlun-node-manager-$klustron_VERSION.tgz.bak &>/dev/null &&\
  mv kunlun-server-$klustron_VERSION.tgz  kunlun-server-$klustron_VERSION.tgz.bak &>/dev/null &&\
  mv kunlun-storage-$klustron_VERSION.tgz kunlun-storage-$klustron_VERSION.tgz.bak  &>/dev/null &&\
	rm -f kunlun-cluster-manager-$klustron_VERSION.tgz kunlun-node-manager-$klustron_VERSION.tgz kunlun-server-$klustron_VERSION.tgz kunlun-storage-$klustron_VERSION.tgz kunlun-xpanel-$klustron_VERSION.tar.gz &>/dev/null 
	cd - 

fi


if nc -z 192.168.0.104  14000 ;then
	python2 setup_cluster_manager.py --action=download --downloadsite=internal --downloadtype=daily_rel --product_version=$klustron_VERSION &>/dev/null
   if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}Klustron数据库安装包已经下载失败毕$COL_END" 
    exit
   fi

else
	python2 setup_cluster_manager.py --action=download --downloadsite=devsite  --downloadtype=daily_rel --product_version=$klustron_VERSION &>/dev/null
   if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}Klustron数据库安装包已经下载失败毕$COL_END" 
    exit
   fi
fi



if [[ -s clustermgr/kunlun-storage-$klustron_VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-storage-$klustron_VERSION.tgz &&\
	cd kunlun-storage-$klustron_VERSION/dba_tools  &&   sed  -ri  's#^innodb_page_size=.*$#innodb_page_size=16384#g'   template-rbr.cnf &&\
  #&& sed  -ri  '/rocksdb/d'   template-rbr.cnf  
	cd  ../..  &&  rm  -f kunlun-storage-$klustron_VERSION.tgz  &&  tar -czf kunlun-storage-$klustron_VERSION.tgz  kunlun-storage-$klustron_VERSION && rm -fr  kunlun-storage-$klustron_VERSION  && cd ../
  if [[ $? -eq 0 ]];then
    echo -e "$COL_START${GREEN}Klustron数据库安装包已经下载完毕$COL_END" 
   else
    echo -e "$COL_START${RED}Klustron数据库安装包已经下载失败毕$COL_END" 
    exit
  fi
  
  
  
else
	
   echo -e "$COL_START${RED}请检查kunlun-storage-$VERSION.tgz文件重新打包失败$COL_END"
   exit
	
fi


}





install_script(){

for i in install clean start stop
do

if [[ "$mdc" == "null"  ]];then
  python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$klustron_VERSION --action=$i  &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END" 
    exit
  fi

else
  python2 setup_cluster_manager.py --autostart --config=$config_json  --multipledc --product_version=$klustron_VERSION  --action=$i &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END"  
    exit
  fi


fi

done


}


install_database(){

if [[ -s clustermgr/clean.sh && -s clustermgr/install.sh ]];then
  sh clustermgr/clean.sh  && sh clustermgr/install.sh

else
  echo -e "$COL_START${RED}请检查安装/卸载文件是否存在$COL_END"  
fi


}





#---------------集群安装------------------#

download_software
install_script
