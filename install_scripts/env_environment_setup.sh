#!/bin/bash



# 控制机上面创建kunlun用户,以便后续切换此用户安装集群

if [ -f "/etc/os-release" ]; then
  . /etc/os-release
  #echo  -e "$COL_START${GREEN}正在控制机上创建用户名$COL_END"
  
  
  
    if [[ "$ID" == "ubuntu" ]]; then
      #echo  -e "$COL_START${GREEN}OS is Ubuntu$COL_END"
        
        
        if ! id $klustron_user &>/dev/null;then 
	        #groupadd -g 1007 $klustron_user 
          #useradd  -u 1007 -g 1007 $klustron_user
	        sudo useradd -r -m -s /bin/bash  $klustron_user  &>/dev/null   &&\
	        sudo echo -e "$passwd\n$passwd"|sudo passwd $klustron_user &>/dev/null       
  
	          if [[ $? == 0 ]];then
             if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
                 if [[ $? == 0 ]];then
                   echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
                 fi
             fi
   
            else
              echo  -e "$COL_START${RED}$klustron_user User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
            fi
           

        else
          if ! sudo egrep -q "^$control_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sudo sed -ri '/Members of the admin group may gain root privileges/i '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
            echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
            fi
          fi
     
 
        fi





      
      
      
      elif [[ "$ID" == "centos" ]]; then
        #echo  -e "$COL_START${GREEN}OS is CentOS$COL_END"
        
      
          if ! id $klustron_user &>/dev/null;then 
  	        #groupadd -g 1007 $klustron_user 
            #useradd  -u 1007 -g 1007 $klustron_user
  	        sudo useradd  $klustron_user &>/dev/null &\
  	        echo "$passwd"|sudo passwd  --stdin $klustron_user  &>/dev/null
   
  	        if [[ $? == 0 ]];then 
                   
             if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
               sudo sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  #&>/dev/null 
               if [[ $? == 0 ]];then
                 echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
               else 
                 echo  -e "$COL_START${RED}$klustron_user权限配置失败(sudoers)$COL_END"
                 exit
               fi
             fi
     
            else
              echo  -e "$COL_START${RED}$klustron_user User created failed $USER不是root用户或没有具有root权限$COL_END"
              exit
              exit
            fi
  
         else
          if ! sudo egrep -q "^$klustron_user.*NOPASSWD: ALL$"  /etc/sudoers;then
            sudo sed -ri '/Allow root to run any commands anywhere/a '${klustron_user:-kunlun}'  ALL=(ALL)  NOPASSWD: ALL'  /etc/sudoers  &>/dev/null 
            if [[ $? == 0 ]];then
              echo  -e "$COL_START${GREEN}$klustron_user User created successfully$COL_END"
            else
              echo  -e "$COL_START${RED}$klustron_user权限配置失败(sudoers)$COL_END"
              exit
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







if id $klustron_user &>/dev/null;then
  sudo chown -R $klustron_user:$klustron_user $(pwd|awk  -F '/'  '{print "/"$2}') &>/dev/null 
    if [[ $? -ne 0 ]];then
      echo -e "$COL_START${RED}控制机上cloudnative目录权限设置失败$COL_END"
      exit
    fi
else
  echo -e "$COL_START${RED}控制机$klustron_user用户不存在$COL_END"
  exit
fi



