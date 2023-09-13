#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
klustron_VERSION=1.2.1
#passwd='3G7NtoxW3NQql2ec'
passwd='kunlun#'
klustron_key=$(pwd)

custom_json='custom.json'
config_json='../klustron_config.json'

host_setup='host_setup.sh'
host_docker='host_docker.sh'


#获取kunlun用户,目录,IP等信息




if ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit


elif [[ $(echo `pwd`|grep 'cloudnative/cluster/install_scripts$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster/install_scripts目录下 $COL_END"
	exit 
 

fi  
  
  






if [[ ! -s  $custom_json ]] ;then
  echo  -e "$COL_START${RED}当前目录下不存在$custom_json配置文件$COL_END" 
  exit
else
  if ! jq  '.'  $custom_json &>/dev/null;then
    echo -e "$COL_START$RED$custom_json syntax error$COL_END"
    exit
  else 
    control_machines=($(jq  '.user,.password,.sshport'  $custom_json|xargs))
    machines_list=($(jq '.machines[].ip' $custom_json|sort -u|xargs))
  fi  
  
fi
 
 
 
if [[ ! -s  $config_json ]] ;then
  echo  -e "$COL_START${RED}上级目录不存在$config_json配置文件$COL_END" 
  exit

else
  if ! jq  '.'  $config_json &>/dev/null;then
    echo -e "$COL_START$RED$config_json syntax error$COL_END"
    exit
  else 
    klustron_user=$(jq  '.machines[].user'  $config_json|sort|uniq|xargs)
    klustron_basedir=$(jq  '.machines[].basedir'  $config_json|sort|uniq|xargs)
    klustron_xpanel_list=$(jq  '.xpanel.ip'  $config_json |xargs)
    klustron_xpanel_port=$(jq  '.xpanel.port'  $config_json |xargs)   
  fi  


fi





  
  
  









