#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
klustron_VERSION=1.2.1
passwd='3G7NtoxW3NQql2ec'



custom_json='custom.json'
config_json='../klustron_config.json'
control_machines=($(jq  '.user,.password,.sshport'  $custom_json|xargs))
machines_list=($(jq '.machines[].ip' $custom_json|xargs))
host_setup='host_setup.sh'

#获取kunlun用户,目录,IP等信息
klustron_user=$(jq  '.machines[].user'  $config_json|sort|uniq|xargs)
klustron_basedir=$(jq  '.machines[].basedir'  $config_json|sort|uniq|xargs)
klustron_xpanel_list=$(jq  '.xpanel.ip'  $config_json |xargs)
klustron_xpanel_port=$(jq  '.xpanel.port'  $config_json |xargs)


if [[ ! -s  $custom_json ]] ;then
  echo  -e "$COL_START${RED}当前目录下不存在$custom_json配置文件$COL_END" 
  exit
  
elif [[ ! -s  $config_json ]] ;then
  echo  -e "$COL_START${RED}上级目录不存在$config_json配置文件$COL_END" 
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
 

elif [[ ${klustron_user} != "$USER" ]];then
  echo -e "$COL_START$RED 请在${klustron_user}用户下执行脚本$0$COL_END"
  exit


fi  










distribution_klustron_key(){

if [[ ! -s $HOME/.ssh/id_rsa  ]];then
 ssh-keygen -t rsa -N '' -f $HOME/.ssh/id_rsa -q 
fi


for i in $(seq 0 $((${#machines_list[*]}-1)))
do






# for host






expect <<EOF  &>/dev/null

	spawn  ssh-copy-id -f  -p${control_machines[2]}    ${klustron_user}@${machines_list[$i]}
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF




expect <<EOF   >/tmp/klustron_key.log  2>/dev/null

	
  spawn  scp  -rp -P${control_machines[2]}   $HOME/.ssh/id_rsa  $HOME/.ssh/id_rsa.pub   ${klustron_user}@${machines_list[$i]}:$HOME/.ssh
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "$passwd\n" }
		
	
	}
	expect eof

EOF




if [[ $(sed -n '/100%/p'  /tmp/klustron_key.log|wc -l) == 2 ]];then
  echo -e "$COL_START${GREEN}${machines_list[$i]}主机为klustron数据库用户${klustron_user}配置免密成功$COL_END"   
else
  echo -e "$COL_START${RED}${machines_list[$i]}主机为klustron数据库用户${klustron_user}配置免密失败$COL_END"
  let count_key_distribution_file++
fi



 
done


if [[ $count_key_distribution_file -ge 1 ]] ;then
	exit
fi



}



distribution_klustron_key
