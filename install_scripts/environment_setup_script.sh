#!/bin/bash
. ./env_setup_script_2.sh


check_machines_sshport_passwd(){

for i in  $(seq 0 $((${#machines_list[*]}-1)))
do

	    
    if ! nc -z  ${machines_list[$i]} ${control_machines[2]};then 
      echo -e "$COL_START${RED}主机${machines_list[$i]}端口${control_machines[2]}有异常,无法连接,请检查网络$COL_END" 
      let count_host_sshport++
      continue  
    fi
    
    
   


done


if [[ $count_host_sshport -ge 1 ]];then
  exit
fi







for i in  $(seq 0 $((${#machines_list[*]}-1)))
do

    
         
         
  expect <<EOF  >/dev/null 2>&1

  spawn ssh -p${control_machines[2]} ${control_machines[0]}@${machines_list[$i]} "echo Password is correct" 
  expect {
    "yes/no" { send "yes\n"; exp_continue }
    "password:" {
        send "${control_machines[1]}\r"
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
    echo -e "$COL_START${RED}${control_machines[0]}@${machines_list[$i]}连接异常无法连接,请检用户名或密码$COL_END"
    let count_machines_passwd++
   
  fi  
    


done



if [[ $count_machines_passwd -ge 1 ]];then
  exit
fi






}












check_klustron_exist(){


for i in $(seq 0 $((${#machines_list[*]}-1)))
	do
  

    

expect <<EOF  >/tmp/node_mgr 2>/dev/null
	#spawn  ssh -p${control_machines[2]} ${klustron_user}@${machines_list[$i]} "test -s ${klustron_basedir}/kunlun-node-manager-$klustron_VERSION/bin/start_node_mgr.sh"


  spawn  ssh -p${control_machines[2]} ${control_machines[0]}@${machines_list[$i]} "ps aux | grep -w '${klustron_basedir}/kunlun-node-manager-${klustron_VERSION}' | grep -v grep|wc -l" 
   
  	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "control_machines[1]\n" }
		
	
	}
 

	expect eof

EOF


node_mgr=$(sed -n '/^2/p' /tmp/node_mgr|dos2unix)  



#echo $node_mgr

if [[ $node_mgr -eq 2  ]];then
  let count_klustron_exist++
  echo -e "$COL_START${RED}主机${machines_list[$i]}上已经安装有klustron数据库无法安装..........$COL_END"  
  
fi

    
done



if [[ $count_klustron_exist -ge 1 ]];then 
  exit
fi










}










distribution_file(){



if [[ -s ${host_setup} ]];then
  
  for i in $(seq 0 $((${#machines_list[*]}-1)))
  do
  
    
    
    #echo "...............${ip_list[i]}.................."
    #echo "Upload files  ${file_name} to ${ip_list[i]}"
expect <<EOF  >/dev/null 2>&1

	spawn  sudo scp -P${control_machines[2]}  -rp ${host_setup}   ${control_machines[0]}@${machines_list[$i]}:/tmp
  
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${control_machines[1]}\n" }
		
	
	}
	expect eof

EOF


if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}Upload files  ${host_setup} to ${machines_list[$i]} successful$COL_END"   
else
  echo -e "$COL_START${RED}${control_machines[0]}@${machines_list[$i]}文件拷贝失败$COL_END"
  let count_distribution_host_file++
fi


done





else
  echo -e "$COL_START${RED}当前目录不存在${host_setup}文件$COL_END"
  exit 
fi




#需要安装docker的主机打上标记

expect <<EOF  >/dev/null 2>&1
  spawn  sudo ssh -p${control_machines[2]} ${control_machines[0]}@${klustron_xpanel_list} "sudo echo 'docker' > /tmp/docker.log"
  
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${control_machines[1]}\n" }
		
	
	}
	expect eof

EOF






if [[ $? == 0 ]];then
  echo -e "$COL_START${GREEN}${control_machines[0]}@${klustron_xpanel_list} docker-flag写人successful$COL_END"   
else
  echo -e "$COL_START${RED}${control_machines[0]}@${klustron_xpanel_list} docker-flag写人失败$COL_END"
  let count_distribution_docker_flag++
fi





}









execute_file(){


#for xpanel
for i in  $(seq 0 $((${#machines_list[*]}-1)))
do




expect <<EOF  >/tmp/check_flag.log #>/dev/null 2>&1
  spawn  sudo ssh -p${control_machines[2]}  ${control_machines[0]}@${machines_list[$i]} "test -f /tmp/${host_setup} && sudo bash /tmp/${host_setup} ${klustron_user}  ${klustron_basedir}" 
	expect {
		"yes/no" { send "yes\n"; exp_continue }
		"password" { send "${control_machines[1]}\n" }
		
	
	}
	expect eof

EOF




if egrep -q 'docker.*failed' /tmp/check_flag.log ;then
  echo  -e "$COL_START${RED}请检查${machines_list[$i]}主机上是否安装好docker并确定已经成功启动$COL_END"   
  let count_docker_flag++
elif egrep -q 'Basic.*failed' /tmp/check_flag.log ;then
  echo  -e "$COL_START${RED}请检查${machines_list[$i]}主机初始化环境失败$COL_END"  
  let count_Basic_flag++
else 
  echo  -e "$COL_START${GREEN}请检查${machines_list[$i]}主机初始化环境成功$COL_END" 
fi



done



if [[ $count_docker_flag -ge 1 ]] || [[ $count_Basic_flag -ge 1 ]];then
	exit
fi


}







distribution_klustron_key(){

sudo su - $klustron_user -c   "cd $klustron_key && bash key_distribution.sh"





}










check_machines_sshport_passwd

#check_klustron_exist

#distribution_file

#execute_file

#distribution_klustron_key