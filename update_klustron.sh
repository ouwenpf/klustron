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
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 

fi




download_software(){

if [[ -d clustermgr ]];then
	cd  clustermgr &&\
	rm -f kunlun-cluster-manager-$VERSION.tgz kunlun-node-manager-$VERSION.tgz kunlun-server-$VERSION.tgz kunlun-storage-$VERSION.tgz kunlun-xpanel-$VERSION.tar.gz
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

if [[ -s clustermgr/kunlun-storage-$VERSION.tgz ]];then
	cd clustermgr &&  tar xf kunlun-storage-$VERSION.tgz &&\
	cd kunlun-storage-$VERSION/dba_tools  &&   sed  -ri  's#^innodb_page_size=.*$#innodb_page_size=16384#g'   template-rbr.cnf #&& sed  -ri  '/rocksdb/d'   template-rbr.cnf
	cd  ../..  &&  rm  -f kunlun-storage-$VERSION.tgz  &&  tar -czf kunlun-storage-$VERSION.tgz  kunlun-storage-$VERSION && rm -fr  kunlun-storage-$VERSION
  cd ../
else
	
   echo -e "$COL_START${RED}请检查kunlun-storage-$VERSION.tgz文件是否完整和存在$COL_END"
   exit
	
fi


}


install_script(){

for i in install clean start stop
do

if [[ "$mdc" == "null"  ]];then
  python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i  &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END" 
    exit
  fi

else
  python2 setup_cluster_manager.py --autostart --config=$config_json  --multipledc --product_version=$VERSION  --action=$i &>/dev/null
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


echo -e "\e[31m 
Welcome to the Klusteron database  system
-------------------------------------------------------------- \e[0m\e[32m 

1. 生成安装/卸载脚本

2. 下载更新包不更新系统
 
3. 下载更新包并重新安装数据库系统(测试环境专用,生产环境禁止使用)

\e[0m\e[31m 
---------------------------------------------------------------\e[0m"


read -t 300 -p "请输入操作序号: "   oper_id

case $oper_id in 
1)
	install_script
  if [[ $? -eq 0 ]];then
    echo  -e "$COL_START${GREEN}生成安装/卸载脚本成功$COL_END"
  fi
	;;
	
2)
	install_script &&  download_software
  if [[ $? -eq 0 ]];then
    echo  -e "$COL_START${GREEN}下载更新包成功$COL_END"
  fi
	;;
 
 
3)
	install_script &&  download_software  && install_database
  if [[ $? -eq 0 ]];then
    echo  -e "$COL_START${GREEN}重新安装数据库系统成功$COL_END"
  fi
	;;

*) 
	echo "请输入正确的操作序号"
	;;



esac





