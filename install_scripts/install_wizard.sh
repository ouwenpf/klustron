#!/bin/bash


COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'



if ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit
fi


if [[ -f "/etc/os-release" ]]; then
    source /etc/os-release
    
      if [[ "$ID" == "ubuntu" ]]; then
        echo  -e "$COL_START${GREEN}正在检查配置信息.....$COL_END"
        echo  -e "$COL_START${GREEN}安装klustron数据库集群之前先阅读以下内容.....$COL_END"
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
        echo  -e "$COL_START${GREEN}正在检查配置信息.....$COL_END"
        echo  -e "$COL_START${GREEN}安装klustron数据库集群之前先阅读以下内容.....$COL_END"
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











while true; do

  echo -e "$COL_START$RED"
    #figlet  -c Klustron
    figlet -f big -w 160 "Welcome to Kunlunbase"
  echo -e "$COL_END"


  echo  -e "$COL_START${GREEN}
  欢迎使用Klustron数据库,Klustron是一个分布式 HTAP数据库系统，聚焦于解决各行业的应用软件 Web 系统、
  和 SaaS云服务在存储、管理和利用海量关系型数据,以及支撑高并发高负载的事务处理和数据读写服务,从而
  为应用软件开发商、服务商和最终用户创造价值.
  有关Klustron分布式数据详细信信息请查询泽拓科技(深圳)有限责任官方网站:https://www.kunlunbase.com/
  
  安装Klustron分布式数据库需要遵循以下主要事项，以确保顺利完成部署过程：
  1.管理员权限:请确保您使用root用户或者具有root权限的用户来运行安装脚本，以确保对系统进行必要的配置和安装.
  2.程序目录和下载:建议创建目录/softwares/
  3.编辑配置文件：
    进入程序下载目录/softwares/cloudnative/cluster/install_scripts,使用vim或其他文本编辑器打开custom.json文件进行配置.
    在配置文件中,您需要进行一些少量的修改,主要是设置相关IP地址.如果您需要更详细的集群安装配置信息请查阅官方文档：
    Klustron官方详细配置http://doc.klustron.com/zh/install_by_scripts.html
    如果在配置过程中遇到任何疑问,随时联系泽拓科技的售后人员,我们将迅速提供帮助和支持
  4.执行集群安装:最后在程序下载目录/softwares/cloudnative/cluster/install_scripts下,
    使用以下命令以sudo bash install_wizard.sh脚本,开始集群安装
    
  遵循这些主要事项,您将能够成功安装Klustron分布式数据库并配置您的集群环境.如有任何进一步的疑问或需要帮助随时与泽拓科技售后人员联系我们将尽力快速解决您的问题.
  $COL_END"
  
  echo -e "$COL_START${GREEN}如配置好按回车键继续安装程序退出请输入q|Q$COL_END" 
    read -t 300 -rsn1 input
    
    if [[ "$input" == "q" || "$input" == "Q" ]]; then
        exit
    elif [[ "$input" == "" ]]; then
        break
    fi 
done





bash  klustron_config_file.sh 
bash  environment_setup_script.sh










