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



if [[ ! -s $config_json ]]  ||  [[ $# -ne 3 ]]; then
	echo -e "$COL_START${RED}Usage $0 args file_json $COL_END"
  exit
  
  
elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit


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



elif ! jq  '.machines[].user'  $config_json |sed 's/null/"kunlun"/g'|sort -rn|uniq|egrep   -wq  "$USER";then
  echo -e  "$COL_START$RED$config_json中没有设置用户:$USER,请到对应的用户下执行脚本$COL_END"
  exit  
!



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










control_machine(){



if [ -f "/etc/os-release" ]; then
  source /etc/os-release
  echo  -e "$COL_START${GREEN}正在控制机上创建用户名$COL_END"
  
  
  
    if [[ "$ID" == "ubuntu" ]]; then
      echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        
        
        if ! id $control_user &>/dev/null;then 
	        #groupadd -g 1007 $klustron_user 
          #useradd  -u 1007 -g 1007 $klustron_user
	        sudo useradd -r -m -s /bin/bash  $control_user  &>/dev/null   &&\
	        sudo echo -e "kunlun#\nkunlun#"|sudo passwd $control_user &>/dev/null       
  
	          if [[ $? == 0 ]];then
             if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               sudo sed -ri '/Members of the admin group may gain root privileges/i '${control_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
                 if [[ $? == 0 ]];then
                   echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
                 fi
             fi
   
            else
              echo  -e "$COL_START${RED}$1 User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
            fi
           

        else
          if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sudo sed -ri '/Members of the admin group may gain root privileges/i '${control_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
            echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
            fi
          fi
     
 
        fi





      
      
      
      elif [[ "$ID" == "centos" ]]; then
        echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        
      
          if ! id $control_user &>/dev/null;then 
  	        #groupadd -g 1007 $klustron_user 
            #useradd  -u 1007 -g 1007 $klustron_user
  	        sudo useradd  $control_user  &>/dev/null   &&\
  	        echo 'kunlun#'|sudo passwd  --stdin $control_user &>/dev/null 
   
  	        if [[ $? == 0 ]];then
                   
             if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               sed -ri '/Allow root to run any commands anywhere/a '${control_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
               if [[ $? == 0 ]];then
                 echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
               fi
             fi
     
            else
              echo  -e "$COL_START${RED}$1 User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
            fi
  
         else
          if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sed -ri '/Allow root to run any commands anywhere/a '${control_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
              echo  -e "$COL_START${GREEN}$1 User created successfully$COL_END"
            fi
          fi
       
   
        fi      
        
      
      
      
      else
        echo  -e "$COL_START$RED未知系统$COL_END"
        exit
      fi
  
else
  echo "os-release文件不存,未知系统"
  exit
fi






}








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





check_klustron_exist(){


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
    


  
    

expect <<EOF  >/tmp/node_mgr 2>/dev/null
	#spawn  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "test -s ${basedir_list[$i]}/kunlun-node-manager-$klustron_VERSION/bin/start_node_mgr.sh"


  spawn  ssh -p${sshport_list[$i]} ${user_list[$i]}@${ip_list[$i]} "ps aux | grep -w '${basedir_list[$i]}/kunlun-node-manager-${klustron_VERSION}' | grep -v grep|wc -l" 
   
  	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
 

	expect eof

EOF


node_mgr=$(sed -n '2p' /tmp/node_mgr|dos2unix) 



echo $node_mgr

if [[ $node_mgr -eq 2  ]];then
  let count_klustron_exist++
  echo -e "$COL_START${RED}主机${ip_list[$i]}上已经安装有klustron数据库无法安装..........$COL_END"  
  
fi

    
done



if [[ $count_klustron_exist -ge 1 ]];then 
  exit
fi










}














distribution_file(){



if [[ -s ${init_file} ]];then
  
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
    
    #echo "...............${ip_list[i]}.................."
    #echo "Upload files  ${file_name} to ${ip_list[i]}"
expect <<EOF  >/dev/null 2>&1

	spawn  sudo scp -P${sshport_list[$i]}  -rp ${init_file}   ${user_passwd[0]}@${ip_list[$i]}:/tmp
  
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF


if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}Upload files  ${init_file} to ${ip_list[$i]} successful$COL_END"   
else
  echo -e "$COL_START${RED}${user_passwd[0]}@${ip_list[$i]}文件拷贝失败$COL_END"
  let count_distribution_host_file++
fi


done










# for xpanel




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
  spawn  sudo scp -P${xpanel_sshport[$i]}  -rp ${init_file}   ${user_passwd[0]}@${xpanel_ip[$i]}:/tmp
   
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF


if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}Upload files  ${init_file} to ${xpanel_ip[$i]} successful$COL_END"   
else
  echo -e "$COL_START${RED}${user_passwd[0]}@${xpanel_ip[$i]}文件拷贝失败$COL_END"
  let count_distribution_xpanel_file++
fi





expect <<EOF  >/dev/null 2>&1
  spawn  sudo ssh -p${xpanel_sshport[$i]} ${user_passwd[0]}@${xpanel_ip[$i]} "sudo echo 'docker' > /tmp/docker.log"
  
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF






if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}Upload files  ${init_file} to ${xpanel_ip[$i]} successful$COL_END"   
else
  echo -e "$COL_START${RED}${user_passwd[0]}@${xpanel_ip[$i]}docker标准写人失败$COL_END"
  let count_distribution_docker_flag++
fi







done 
  

  
else
  echo -e "$COL_START${RED}当前目录不存在${init_file}文件$COL_END"
  exit 
fi





if [[ $count_distribution_host_file -ge 1 ]] || [[ $count_distribution_xpanel_file -ge 1  ]] || [[ $count_distribution_docker_flag -ge 1  ]];then
  exit
fi






}







execute_file(){


#for xpanel
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
  spawn  sudo ssh -p${xpanel_sshport[$i]}  ${user_passwd[0]}@${xpanel_ip[$i]} "test -f /tmp/${init_file} && sudo sh /tmp/${init_file} ${user_list[$i]}  ${basedir_list[$i]}" >/tmp/start_docker_flag.log
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF




if egrep -q 'docker.*failed' /tmp/start_docker_flag.log ;then
  echo  -e "$COL_START${RED}docker start or install failed$COL_END"   
  let count_start_docker_flag++
fi



done


if [[ count_start_docker_flag++ -ge 1 ]];then
	exit
fi





#for host

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
  




expect <<EOF  >/dev/null 2>&1

	spawn  sudo ssh -p${sshport_list[$i]}    ${user_passwd[0]}@${ip_list[$i]}  "test -f /tmp/${init_file} && sudo sh /tmp/${init_file} ${user_list[$i]}  ${basedir_list[$i]} || exit"
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${user_passwd[1]}\n" }
		
	
	}
	expect eof

EOF



done 





}





set_permission(){
  if id $control_user &>/dev/null;then
    sudo chown -R $control_user:$control_user /softwares 
  else
    echo -e "$COL_START${RED}控制机/softwares目录权限设置失败$COL_END"
    exit
  fi


}




distribution_kunlun_key(){

sudo su - $control_user -c   "cd /softwares/cloudnative/cluster/ && sh init_key.sh $config_json"


}







install_klustron_cluster(){

sudo su - $control_user -c   "cd /softwares/cloudnative/cluster/ && sh init_database.sh $config_json"


}














#---------------环境准备-----------------#
control_machine
check_xpanel_sshport_passwd
check_host_sshport_passwd
distribution_file
execute_file
set_permission
#install_klustron_cluster

















