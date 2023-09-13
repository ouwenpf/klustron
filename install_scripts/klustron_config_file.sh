#!/bin/bash

COL_START='\e['
COL_END='\e[0m'
RED='31m'
GREEN='32m'
YELLOW='33m'

custom_json='custom.json'
config_json='../klustron_config.json'



if [[ ! -s  $custom_json ]] ;then
  echo  -e "$COL_START${RED}当前目录下不存在$custom_json配置文件$COL_END" 
  exit

elif ! nc -z  www.kunlunbase.com  80  &>/dev/null ;then   
  echo  -e "$COL_START$RED当前主机网络异常$COL_END"
  exit

elif [[ $(echo `pwd`|grep 'cloudnative/cluster/install_scripts$'|wc -l)  -ne 1 ]]; then
	echo  -e "$COL_START$RED请确保当前$0脚本在../cloudnative/cluster/install_scripts目录下 $COL_END"
	exit 
 
fi  
  
  

if ! jq  '.'  custom.json &>/dev/null;then
  echo -e "$COL_START$RED$custom_json syntax error$COL_END"
  exit    
else
  control_machines=($(jq  '.user,.password,.sshport'  $custom_json|xargs))
  machines_list=($(jq '.machines[].ip' $custom_json|sort -u|xargs))
fi  


# 检查IP数量是否小于3，如果是，则显示消息并退出
if [ ${#machines_list[@]} -lt 3 ]; then
    echo  -e "$COL_START${RED}机器数量小于3，无法生成配置文件$COL_END"
    exit 
fi





# 生成 machines 节点
machines=""
for ip in "${machines_list[@]}"; do
    machines+=$(cat <<EOF
        {
            "ip": "$ip",
	          "sshport": ${control_machines[2]},
            "basedir": "/home/tanyueyun/klustron",
            "user": "tanyueyun"
        },
EOF
)
done
machines="${machines%,}"  # 移除最后一个对象后面的逗号 

# 随机选择3个 IP 作为 meta.nodes 和 cluster_manager.nodes 的 IP
selected_ips=()
while [ ${#selected_ips[@]} -lt 3 ]; do
    random_index=$((RANDOM % ${#machines_list[@]}))
    ip="${machines_list[$random_index]}"
    if [[ ! " ${selected_ips[@]} " =~ " ${ip} " ]]; then
        selected_ips+=("$ip")
    fi
done

# 生成 meta.nodes 节点
meta_nodes=""
for ip in "${selected_ips[@]}"; do
    meta_nodes+=$(cat <<EOF
            {
                "ip": "$ip",
                "port": 56001
            },
EOF
)
done
meta_nodes="${meta_nodes%,}"  # 移除最后一个对象后面的逗号


# 生成 cluster_manager.nodes 节点
cluster_manager_nodes=""
for ip in "${selected_ips[@]}"; do
    cluster_manager_nodes+=$(cat <<EOF
            {
                "ip": "$ip",
                "brpc_http_port": 58000,
                "brpc_raft_port": 58001,
                "prometheus_port_start": 59010
            },
EOF
)
done
cluster_manager_nodes="${cluster_manager_nodes%,}"   # 移除最后一个对象后面的逗号

# 生成 node_manager.nodes 节点
node_manager_nodes=""
for ip in "${machines_list[@]}"; do
    node_manager_nodes+=$(cat <<EOF
            {
                "ip": "$ip",
                "brpc_http_port": 58002,
                "tcp_port": 58003,
                "prometheus_port_start": 58010,
                "storage_portrange": "57000-58000",
                "server_portrange": "47000-48000"
            },
EOF
)
done
node_manager_nodes="${node_manager_nodes%,}"  # 移除最后一个对象后面的逗号

# 随机选择一个 IP 作为 xpanel 的 ip
random_xpanel_ip=${machines_list[$RANDOM % ${#machines_list[@]}]}

# 生成 xpanel 节点
xpanel=$(cat <<EOF
        "xpanel": {
            "ip": "$random_xpanel_ip",
            "port": 18080,
            "image": "registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:VERSION"
        }
EOF
)


if [[ ! -s ../klustron_config.json ]] ;then
# 生成完整的 JSON 配置文件
cat <<EOF > ../klustron_config.json
{
    "machines": [
        $machines
    ],
    "meta": {
        "ha_mode": "rbr",
        "config": {
            "innodb_buffer_pool_size": "1024MB",
            "innodb_page_size": 16384,
            "max_binlog_size": 1073741824,
            "lock_wait_timeout": 1200,
            "innodb_lock_wait_timeout": 1200
        },
        "nodes": [
            $meta_nodes
        ]
    },
    "cluster_manager": {
        "nodes": [
            $cluster_manager_nodes
        ]
    },
    "node_manager": {
        "nodes": [
            $node_manager_nodes
        ]
    },
    $xpanel
}
EOF


  if ! jq  '.'  $config_json &>/dev/null;then
    echo -e "$COL_START$RED$config_json syntax error$COL_END"
    exit
  else 
    echo  -e "$COL_START${GREEN}主配置文件已生成$COL_END"
  fi  


  
else

  if ! jq  '.'  $config_json &>/dev/null;then
    echo -e "$COL_START$RED$config_json syntax error$COL_END"
    exit
  else 
    echo  -e "$COL_START${GREEN}主配置文件已生成$COL_END"
    
  fi  


fi 
