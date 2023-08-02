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
else 
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json) 

fi



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
	
   echo -e "$COL_START${RED}Modification failed Please check if the file exists$COL_END"
   exit
	
fi


for i in install clean start stop
do

if [[ "$mdc" == "null"  ]];then
  python2 setup_cluster_manager.py --autostart --config=$config_json   --product_version=$VERSION --action=$i  &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}$config_json configuration error, please check$COL_END" 
    exit
  fi

else
  python2 setup_cluster_manager.py --autostart --config=$config_json  --multipledc --product_version=$VERSION  --action=$i &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}$config_json configuration error, please check$COL_END" 
    exit
  fi


fi

done