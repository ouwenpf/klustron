#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'




if ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit


elif [[ ! -d  /softwares   ]];then
  sudo mkdir -p /softwares &>/dev/null  
  if [[ $? -ne 0 ]];then
     echo -e "$COL_START$RED创建/softwares目失败录$COL_END"
     exit
  fi
    
fi





if [[ -f "/etc/os-release" ]]; then
    source /etc/os-release
    
      if [[ "$ID" == "ubuntu" ]]; then
        echo -e "$COL_START$GREEN正在下载最新程序请稍后........$COL_END"
        #echo  -e "$COL_START${GREEN}安装klustron数据库集群之前先阅读以下内容.....$COL_END"
        for i in figlet expect dos2unix jq
        do
           if ! command -v "$1" &> /dev/null; then
             sudo apt-get install -y $i &>/dev/null
             if [[ $? -ne 0  ]];then
               echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
               exit
             fi
           fi
        
        done
        
        
      elif [[ "$ID" == "centos" ]]; then
        echo -e "$COL_START$GREEN正在下载最新程序请稍后........$COL_END"
        #echo  -e "$COL_START${GREEN}安装klustron数据库集群之前先阅读以下内容.....$COL_END"
        for i in figlet expect dos2unix jq
        do
           if ! command -v "$1" &> /dev/null; then
             sudo yum install -y $i &>/dev/null
             if [[ $? -ne 0  ]];then
               echo  -e "$COL_START${RED}$i命令安装失败$COL_END"
               exit
             fi
           fi
        
        done 
        
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit

      fi
    
  else
      echo "os-release文件不存,未知系统"
	    exit
fi













if [[ ! -d  /softwares/cloudnative   ]];then
  
  cd /softwares &&  sudo git clone https://gitee.com/zettadb/cloudnative.git  &>/dev/null
  if [[ $? -eq 0 ]];then
    echo -e "$COL_START$GREEN最新程序下载成功$COL_END"
  else 
    echo -e "$COL_START$RED程序下载失败$COL_END"
    exit
  fi

else
  echo -e "$COL_START$GREEN最新程序下载成功$COL_END"
fi











while true; do
  echo -e "$COL_START$RED为了确保集群安装成功,请您仔细阅读以下内容........$COL_END"
  sleep 3
  echo  -e "$COL_START${GREEN}
  安装Klustron分布式数据库需要遵循以下主要事项，以确保顺利完成部署过程：
  1.配置信息:入门级
    服务器数量：3台
    CPU： 4C
    内存：8GB
    存储：通用型SSD卷
    容量: 300G
    注意:由于数据库服务属于磁盘IO密集型,建议使用固态硬盘
  2.管理员权限:请确保您使用root用户或者具有root权限的用户来运行安装脚本，以确保对系统进行必要的配置和安装.
  3.程序目录和下载:程序下载路径为/softwares/
  4.编辑全局配置文件：
    假如三台服务器
    机器IP:192.168.0.1
           192.168.0.2
           192.168.0.3
    用户名:root,默认为root,可以使用具有root权限的用户,具体根据实际情况配置
    密码:password
    ssh端口:22,默认22,非22端口根据实际情况配置
    配置信息范例如下:
    cd /softwares/cloudnative/cluster/install_scripts
    vim custom.json
    
    {
    "user": "root",  
    "password": "password",
    "sshport": 22,
    "machines": [
        {
        "ip": "192.168.0.1" 
        } ,

        {
        "ip": "192.168.0.2"
        } ,

        {
        "ip": "192.168.0.3"
        }
        ]
    }
    
  4.集群安装:cd /softwares/cloudnative/cluster/install_scripts; sudo bash install_wizard.sh 开始集群安装
  遵循这些主要事项,您将能够成功安装Klustron分布式数据库并配置您的集群环境.如有任何进一步的疑问或需要帮助随时与泽拓科技售后人员联系
  我们将尽力快速解决您的问题.
  $COL_END"
  
  echo -e "$COL_START$RED按q|Q退出,前去集群安装配置........$COL_END" 
  read -t 300 -rsn1 input
    
    if [[ "$input" == "Q" || "$input" == "q" ]]; then
        echo -e "$COL_START${RED}
        cd /softwares/cloudnative/cluster/install_scripts
        vim custom.json
        sudo bash install_wizard.sh 开始集群安装吧!!!
        $COL_END" 
        
        exit
    fi

done

