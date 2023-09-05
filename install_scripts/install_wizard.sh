#!/bin/bash


COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'


while true; do

  echo -e "$COL_START$RED"
    #figlet  -c Klustron
    figlet -f big -w 160 "Welcome to Kunlunbase"
  echo -e "$COL_END"


  echo  -e "$COL_START$GREEN
  欢迎使用Klustron数据库,Klustron是一个分布式 HTAP数据库系统，聚焦于解决各行业的应用软件 Web 系统、
  和 SaaS云服务在存储、管理和利用海量关系型数据,以及支撑高并发高负载的事务处理和数据读写服务,从而
  为应用软件开发商、服务商和最终用户创造价值。
  有关Klustron分布式数据详细信信息请查询泽拓科技(深圳)有限责任官方网站:https://www.kunlunbase.com/
  
  安装Klustron分布式数据库主要事项:
1.请使用root用户或具有root权限的用户运行此脚本
2.程序下载路径为/softwares/cloudnative
3.请切换到目录/softwares/cloudnative/cluster下面,vim cluster_template.json编辑配置文件
  进行少量的配置(配置文件名称可以随意修改),修改对应IP即可(配置文件提供三个主机配置,采用对等配置达到节约资源的目的),
  如果集群超过三个主机可以参考官方详细配置http://doc.klustron.com/zh/install_by_scripts.html
  如果有疑问请及时联系泽拓科技售后人员快速帮您解决
4.在目录/softwares/cloudnative/cluster下执行如: sudo sh install_klustron.sh cluster_template.json root_passwd进行集群安装
  $COL_END"
  
  echo -e "$COL_START${RED}按回车键继续安装程序退出请输入q|Q$COL_END" 
    read -t 300 -rsn1 input
    
    if [[ "$input" == "q" || "$input" == "Q" ]]; then
        exit
    elif [[ "$input" == "" ]]; then
        break
    fi 
done

bash klustron_config_file.sh 
bash environment_setup_script.sh
