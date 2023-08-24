#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'
config_json=$1
user_passwd=($2 $3)
VERSION=1.2.1

if [[ ! -s $config_json ]]  ||  [[ $# -ne 3 ]]; then
	echo -e "$COL_START${RED}Usage $0 args file_json $COL_END"
  exit
  
<<!  
elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit
! 

elif ! command -v jq &>/dev/null  ;then
  echo  -e "$COL_START$RED正在下载jq命令 $COL_END"
  
  if [ -f "/etc/os-release" ]; then
    source /etc/os-release
    
      if [[ "$ID" == "ubuntu" ]]; then
        echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        sudo apt-get install -y jq &&  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
        
      elif [[ "$ID" == "centos" ]]; then
        echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        sudo yum install -y jq  &>/dev/null  &&  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 
        
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit

      fi
    
  else
      echo "os-release文件不存,未知系统"
	    exit
  fi
  

elif ! jq  '.'  $config_json &>/dev/null;then
  echo -e "$COL_START$RED$config_json syntax error$COL_END"
  exit 
  
<<!
elif [[ $(echo `pwd`|grep 'cloudnative/cluster$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster目录下 $COL_END"
	exit 
!


elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中没有设置用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  


else
	ip_list=($(jq  '.machines[].ip'  $config_json |xargs ))
	user_list=($(jq  '.machines[].user'  $config_json |xargs))
	basedir_list=($(jq  '.machines[].basedir'  $config_json |xargs))
	sshport_list=($(jq  '.machines[].sshport'  $config_json |xargs))
  mdc=$(jq  '.node_manager.nodes[0].dc'  $config_json 2>/dev/null) 

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




check_xpanel_sshport_passwd(){

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
	    
    if ! nc -z  ${xpanel_ip[$i]} ${xpanel_sshport[$i]};then 
      echo -e "$COL_START${RED}主机${xpanel_ip[$i]}端口${xpanel_sshport[$i]}有异常,无法连接,请检查网络$COL_END" 
      let count_xpanel_sshport++
      continue  
    fi
    
 

done



if [[ $count_xpanel_sshport -ge 1 ]];then
  exit
fi










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


  expect <<EOF  >/dev/null 2>&1

  spawn ssh -p${xpanel_sshport[$i]} ${user_passwd[0]}@${xpanel_ip[$i]} "echo Password is correct" 
  expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" {
        send "${user_passwd[1]}\r"
        exp_continue
    }
    "Password is correct" {
        puts "Password is correct"
        exit 0
    }
    timeout {
        puts "Connection timed out or password is incorrect"
        exit 1
    }
    eof {
        puts "Failed to connect to remote host"
        exit 1
    }
    "*assword incorrect*" {
        puts "Password is incorrect"
        exit 1
    }
}



	expect eof

EOF


  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}${user_passwd[0]}@${xpanel_ip[$i]}连接异常无法连接,请检用户名或密码$COL_END"
    let count_xplanen_passwd++
   
  fi  
    


done



if [[ $count_xplanen_passwd -ge 1 ]];then
  exit
fi



}

















check_host_sshport_passwd(){

for i in  $(seq 0 $((${#ip_list[*]}-1)))
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
    
    if [[ "${xpanel_port[$i]}" == "null" ]];then
      xpanel_ip[$i]=18080
    fi 
	    
    if ! nc -z  ${ip_list[$i]} ${sshport_list[$i]};then 
      echo -e "$COL_START${RED}主机${ip_list[$i]}端口${sshport_list[$i]}有异常,无法连接,请检查网络$COL_END" 
      let count_host_sshport++
      continue  
    fi
    
    
   


done


if [[ $count_host_sshport -ge 1 ]];then
  exit
fi







for i in  $(seq 0 $((${#ip_list[*]}-1)))
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
    
    if [[ "${xpanel_port[$i]}" == "null" ]];then
      xpanel_ip[$i]=18080
    fi 
	    
         
         
  expect <<EOF  >/dev/null 2>&1

  spawn ssh -p${sshport_list[$i]} ${user_passwd[0]}@${ip_list[$i]} "echo Password is correct" 
  expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" {
        send "${user_passwd[1]}\r"
        exp_continue
    }
    "Password is correct" {
        puts "Password is correct"
        exit 0
    }
    timeout {
        puts "Connection timed out or password is incorrect"
        exit 1
    }
    eof {
        puts "Failed to connect to remote host"
        exit 1
    }
    "*assword incorrect*" {
        puts "Password is incorrect"
        exit 1
    }
}



	expect eof

EOF

    
  if [[ $? -ne 0 ]];then
    echo -e "$COL_START${RED}${user_passwd[0]}@${ip_list[$i]}连接异常无法连接,请检用户名或密码$COL_END"
    let count_host_passwd++
   
  fi  
    


done



if [[ $count_host_passwd -ge 1 ]];then
  exit
fi






}



















distribution_file(){

if [[ -s init_klustron.sh ]];then
  file_name='init_klustron.sh'
  for i in $(seq 0 $((${#ip_list[*]}-1)))
  do
    #echo "...............${ip_list[i]}.................."
    #echo "Upload files  ${file_name} to ${ip_list[i]}"
expect <<EOF  >/dev/null 2>&1

	spawn  sudo scp -P${sshport_list[$i]}  -rp ${file_name}   ${user_passwd[0]}@${ip_list[i]}:/tmp
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF


if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}Upload files  ${file_name} to ${ip_list[i]} successful$COL_END"   
else
  echo -e "$COL_START${RED}${user_passwd[0]}@${ip_list[$i]}文件拷贝失败$COL_END"
  let count_distribution_file++
fi


done 
  
  
  
else
  echo -e "$COL_START${RED}当前目录不存在${file_name}文件$COL_END"
  exit 
fi





if [[ $count_distribution_file -ge 1 ]];then
  exit
fi





}







check_xpanel_sshport_passwd
check_host_sshport_passwd
distribution_file




