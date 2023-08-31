#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
config_json=$1
VERSION=1.2.1




if ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit


elif [[ ! -d  /softwares   ]];then
  sudo mkdir -p /softwares &>/dev/null  &&  cd /softwares &>/dev/null
  if [[ $? -ne 0 ]];then
     echo -e "$COL_START$RED创建/softwares目失败录$COL_END"
     exit
  fi
    
fi



if ! command -v figlet &>/dev/null  ;then
  echo  -e "$COL_START$RED正在下载figlet命令 $COL_END"
  
  if [ -f "/etc/os-release" ]; then
    . /etc/os-release
    
      if [[ "$ID" == "ubuntu" ]]; then
        echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        sudo apt-get install -y figlet expect dos2unix &>/dev/null  
        
      elif [[ "$ID" == "centos" ]]; then
        echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        sudo yum install -y figlet expect dos2unix&>/dev/null  
        
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit
      fi
        
        
  else
    echo "os-release文件不存,未知系统"
    exit

  fi
    

fi







if [[ -d  /softwares/cloudnative   ]];then
  echo -e "$COL_START$GREEN正在下载最新代码$COL_END"
  cd /softwares  &&  sudo rm  -fr cloudnative &>/dev/null  &&  sudo git clone https://gitee.com/zettadb/cloudnative.git &>/dev/null
  if [[ $? -eq 0 ]];then
    echo -e "$COL_START$GREEN最新程序下载成功$COL_END"
  else
    echo -e "$COL_START$RED程序下载失败$COL_END"
    exit
  fi

else
  echo -e "$COL_START$GREEN正在下载最新代码$COL_END"
  cd /softwares &&  sudo git clone https://gitee.com/zettadb/cloudnative.git  &>/dev/null
  if [[ $? -eq 0 ]];then
    echo -e "$COL_START$GREEN最新程序下载成功$COL_END"
  else 
    echo -e "$COL_START$RED程序下载失败$COL_END"
    exit
  fi

fi






#!




while true; do

  echo -e "$COL_START$RED"
    figlet  -c Klustron
  echo -e "$COL_END"


  echo  -e "$COL_START$GREEN
  欢迎使用Klustron数据库,Klustron是一个分布式 HTAP数据库系统，聚焦于解决各行业的应用软件 Web 系统、
  和 SaaS云服务在存储、管理和利用海量关系型数据,以及支撑高并发高负载的事务处理和数据读写服务,从而
  为应用软件开发商、服务商和最终用户创造价值。
  有关Klustron分布式数据详细信信息请查询泽拓科技(深圳)有限责任官方网站:https://www.kunlunbase.com/
  
  安装Klustron分布式数据库主要事项:
1.安装脚本会自动下载最新程序,请使用root用户或具有root权限的用户运行此脚本
2.程序下载路径为/softwares/cloudnative
3.请切换到目录/softwares/cloudnative/cluster下面,vim cluster_template.json编辑配置文件
  进行少量的配置(配置文件名称可以随意修改),修改对应IP即可(配置文件提供三个主机配置,采用对等配置达到节约资源的目的),
  如果集群超过三个主机可以参考官方详细配置http://doc.klustron.com/zh/install_by_scripts.html
  如果有疑问请及时联系泽拓科技售后人员快速帮您解决
4.在目录/softwares/cloudnative/cluster下执行如: sudo sh install_klustron.sh cluster_template.json root_passwd进行集群安装
  $COL_END"
  
  echo -e "$COL_START$RED退出请输入q|Q$COL_END" 
  read -s input
    
    if [[ "$input" == "Q" || "$input" == "q" ]]; then
        #echo "退出程序"
        break
    fi

done
