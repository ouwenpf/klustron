#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
config_json=$1
user_passwd=($2 $3)
klustron_VERSION=1.2.1
init_file='init_klustron.sh'



if [[ ! -s $config_json ]]  ||  [[ $# -ne 1 ]]; then
	echo -e "$COL_START${RED}Usage $0 args file_json $COL_END"
  exit
  
  

elif ! jq  '.'  $config_json &>/dev/null;then
  echo -e "$COL_START$RED$config_json syntax error$COL_END"
  exit 
  

elif [[ $(echo `pwd`|grep 'cloudnative/cluster$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster目录下 $COL_END"
	exit 



elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中没有设置用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  




elif [[ $( jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|wc -l) -ne 1 ]];then
  echo  -e  "$COL_START$RED$config_json存在多个用户,请设置相同的用户,不设置默认为kunlun用户$COL_END"
  exit

elif [[ $( jq  '.machines[].sshport'  $config_json |sed 's/null/"22"/g'|sort -rn|uniq|wc -l) -ne 1 ]];then
  echo  -e  "$COL_START$RED$config_json存在多个ssh端口,请设置相同的sshd端口,不设置默认为22端口$COL_END"
  exit






else
	ip_list=($(jq  '.machines[].ip'  $config_json |xargs ))
	user_list=($(jq  '.machines[].user'  $config_json |xargs))
	basedir_list=($(jq  '.machines[].basedir'  $config_json |xargs))
	sshport_list=($(jq  '.machines[].sshport'  $config_json |xargs))
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
  control_user=$(jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort|uniq|xargs)

fi




if [[ "$mdc" == "null"  ]];then

  xpanel_ip=($(jq  '.xpanel.ip'  $config_json |xargs))
  xpanel_port=($(jq  '.xpanel.port'  $config_json |xargs))
  xpanel_sshport=($(jq  '.xpanel.sshport'  $config_json |xargs))
else
  xpanel_ip=($(jq  '.xpanel.nodes[].ip'  $config_json |xargs))
  xpanel_port=($(jq  '.xpanel.nodes[].port'  $config_json |xargs))
  xpanel_sshport=($(jq  '.xpanel.nodes[].sshport'  $config_json |xargs))

fi






distribution_kunlun_key(){

if [[ ! -s $HOME/.ssh/id_rsa  ]];then
 ssh-keygen -t rsa -N '' -f $HOME/.ssh/id_rsa -q 
fi


for i in $(seq 0 $((${#ip_list[*]}-1)))
do


    if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
    
 
    if [[ "${sshport_list[$i]}" == "null" ]];then
      sshport_list[$i]=22
    fi
    
    if [[ "${xpanel_sshport[$i]}" == "null" ]];then
      if [[ "${sshport_list[$i]}"  == "null" ]];then
        xpanel_sshport[$i]=22
      else
        xpanel_sshport[$i]="${sshport_list[$i]}"
      fi
    fi    
    
    if [[ "${xpanel_port[$i]}" == "null" ]];then
      xpanel_ip[$i]=18080
    fi   
  




# for host






expect <<EOF

	spawn  ssh-copy-id -f  -p${sshport_list[$i]}    ${user_list[$i]}@${ip_list[$i]}
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "3G7NtoxW3NQql2ec\n" }
		
	
	}
	expect eof

EOF




expect <<EOF

	
  spawn  scp  -rp -P${sshport_list[$i]}   $HOME/.ssh/id_rsa  $HOME/.ssh/id_rsa.pub  ${user_list[$i]}@${ip_list[$i]}:$HOME/.ssh
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "3G7NtoxW3NQql2ec\n" }
		
	
	}
	expect eof

EOF



 
done






for i in  $(seq 0 $((${#xpanel_ip[*]}-1)))
do

    if [[ "${user_list[$i]}" == "null" ]];then
      user_list[$i]="kunlun"
    fi 
   
    if [[ "${basedir_list[$i]}" == "null" ]];then
      basedir_list[$i]="/kunlun"
      
    fi
 
    if [[ "${xpanel_sshport[$i]}" == "null" ]];then
      if [[ "${sshport_list[$i]}"  == "null" ]];then
        xpanel_sshport[$i]=22
      else
        xpanel_sshport[$i]="${sshport_list[$i]}"
      fi
    fi
    
    
    
    if [[ "${xpanel_port[$i]}" == "null" ]];then
      xpanel_ip[$i]=18080
    fi 



#for xpanel

expect <<EOF

	spawn  ssh-copy-id -f  -p${xpanel_sshport[$i]}    ${user_list[$i]}@${xpanel_ip[$i]}
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "3G7NtoxW3NQql2ec\n" }
		
	
	}
	expect eof

EOF



expect <<EOF

	
  spawn  scp  -rp -P${xpanel_sshport[$i]}   $HOME/.ssh/id_rsa  $HOME/.ssh/id_rsa.pub  ${user_list[$i]}@${xpanel_ip[$i]}:~/.ssh
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "3G7NtoxW3NQql2ec\n" }
		
	
	}
	expect eof

EOF

done



}



distribution_kunlun_key


