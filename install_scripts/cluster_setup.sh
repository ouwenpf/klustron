#!/bin/bash

. ./env_global.sh
declare -A check_diff
internal_url='http://192.168.0.104:14000/dailybuilds_x86_64/enterprise'
devsite_url='http://zettatech.tpddns.cn:14000/dailybuilds_x86_64/enterprise'

if [[ ${klustron_user} != "$USER" ]];then
  echo -e "$COL_START$RED 请在${klustron_user}用户下执行脚本$0$COL_END"
  exit
fi  


install_script(){

cd ..
for i in install clean start stop
do

if [[ "$mdc" == ""  ]];then
  python2 setup_cluster_manager.py --autostart --config=$(echo $config_json|sed 's#../##g')   --product_version=$klustron_VERSION --action=$i  &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$(echo $config_json|sed 's#../##g')   --product_version=$klustron_VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END" 
    exit
  fi

else
  python2 setup_cluster_manager.py --autostart --config=$(echo $config_json|sed 's#../##g')  --multipledc --product_version=$klustron_VERSION  --action=$i &>/dev/null
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}命令python2 setup_cluster_manager.py --autostart --config=$(echo $config_json|sed 's#../##g')   --product_version=$klustron_VERSION --action=$i执行有误,请单独执行,根据提示错误进行排除问题$COL_END"  
    exit
  fi


fi

done


}



download_software(){

echo -e "$COL_START${GREEN}正在下载Klustron分布式数据库安装包,请勿中断........$COL_END" 



if nc -z 192.168.0.104  14000 ;then
	if [[ -d ./clustermgr ]];then
	for i in kunlun-server kunlun-storage kunlun-cluster-manager  kunlun-node-manager
	do
		if [[ -s clustermgr/$i-$klustron_VERSION.tgz ]];then
	
		  if ! curl -s $internal_url/$i-$klustron_VERSION.tgz|diff - clustermgr/$i-$klustron_VERSION.tgz;then
			  rm -f clustermgr/$i-$klustron_VERSION.tgz 
			  check_diff["$i"]="$i"
		  fi
		else
		  check_diff["$i"]="$i"
		fi
		
	done 
	
	
	  if [[ ${#check_diff[*]} -ge 1 ]];then
		  python2 setup_cluster_manager.py --action=download --downloadsite=internal --downloadtype=daily_rel --product_version=$klustron_VERSION &>/dev/null 
      if [[ $? -ne 0 ]];then
        echo -e "$COL_START${RED}Klustron分布式数据库安装包已经下载失败毕$COL_END" 
        exit
      fi
	
	  fi
	
	fi



else

	if [[ -d ./clustermgr ]];then
	for i in kunlun-server kunlun-storage kunlun-cluster-manager  kunlun-node-manager
	do
		if [[ -s clustermgr/$i-$klustron_VERSION.tgz ]];then
	
		  if ! curl -s $devsite_url/$i-$klustron_VERSION.tgz|diff - clustermgr/$i-$klustron_VERSION.tgz  >/dev/null 2>&1; then 
			  rm -f clustermgr/$i-$klustron_VERSION.tgz 
			  check_diff["$i"]="$i"
		  fi
		else
		  check_diff["$i"]="$i"
		fi
		
	done 
	
	
	  if [[ ${#check_diff[*]} -ge 1 ]];then
		  python2 setup_cluster_manager.py --action=download --downloadsite=devsite --downloadtype=daily_rel --product_version=$klustron_VERSION &>/dev/null
             
      if [[ $? -ne 0 ]];then
        echo -e "$COL_START${RED}Klustron分布式数据库安装包已经下载失败毕$COL_END" 
        exit
      fi

	
	  fi
	
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










install_database(){
 
echo -e "$COL_START${GREEN}正在安装Klustron分布式数据库集群需要一点时间,请耐心等待,请勿中断.......$COL_END"  

if [[ -s clustermgr/clean.sh  && -s clustermgr/install.sh ]];then #&& -s clustermgr/install.sh
  if bash clustermgr/clean.sh && bash clustermgr/install.sh ;then  #&& bash clustermgr/install.sh
  echo -e "$COL_START${GREEN} 
恭喜您已经成功安装好了Klustron分布式数据库集群
我们提供了XPanel GUI工具软件，让DBA通过点击鼠标就可以轻松完成所有的数据库运维管理工作
XPANEL 访问地址：
http://$klustron_xpanel_list:18080/KunlunXPanel/
初始化账户：super_dba
初始化密码：super_dba
XPANEL详细使用手册请阅读官方文档http://doc.klustron.com/zh/XPanel_Manual.html
$COL_END" 
  else
    echo -e "$COL_START${RED}安装失败,请根据报错信息检查$COL_END"  
    exit
  fi
  

else
  echo -e "$COL_START${RED}安装失败,集群安装脚本不存在$COL_END"  
  exit
fi


}

install_script
download_software
install_database
