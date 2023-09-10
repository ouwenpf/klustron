#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
klustron_VERSION=1.2.1

custom_json='custom.json'
config_json='../klustron_config.json'
control_machines=($(jq  '.user,.password,.sshport'  $custom_json|xargs))
machines_list=($(jq '.machines[].ip' $custom_json|sort -u|xargs))
 

if [[ ! -s  $custom_json ]] ;then
  echo  -e "$COL_START${RED}当前目录下不存在$custom_json配置文件$COL_END" 
  exit
elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit
elif ! jq  '.'  custom.json &>/dev/null;then
  echo -e "$COL_START$RED$custom_json syntax error$COL_END"
  exit  

elif [[ $(echo `pwd`|grep 'cloudnative/cluster/install_scripts$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster/install_scripts目录下 $COL_END"
	exit 
 
<<!
elif [[ ${control_machines[0]} != "$USER" ]];then
  echo -e "$COL_START$RED $custom_json中没有设置用户:$USER请到对应的用户下执行脚本$0$COL_END"
  exit
!

fi  
  
  
  
  




