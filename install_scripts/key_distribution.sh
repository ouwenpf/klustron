#!/bin/bash
 . ./env_global.sh

if [[ ${klustron_user} != "$USER" ]];then
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
