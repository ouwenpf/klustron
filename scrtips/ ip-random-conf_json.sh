#!/bin/bash

ip_list=("192.168.0.1" "192.168.0.2" "192.168.0.3" "192.168.0.4"  "192.168.0.5" "192.168.0.6")

# 生成 machines 节点
machines=""
for ip in "${ip_list[@]}"; do
    machines+=$(cat <<EOF
        {
            "ip": "$ip",
            "sshport": 22,
            "basedir": "/home/kunlun/klustron",
            "user": "kunlun"
        },
EOF
)
done
machines="${machines%,}"  # 移除最后一个对象后面的逗号

# 随机选择3个 IP 作为 meta.nodes 和 cluster_manager.nodes 的 IP
selected_ips=()
while [ ${#selected_ips[@]} -lt 3 ]; do
    random_index=$((RANDOM % ${#ip_list[@]}))
    ip="${ip_list[$random_index]}"
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

# 生成 node_manager.nodes 节点
node_manager_nodes=""
for ip in "${ip_list[@]}"; do
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
random_xpanel_ip=${ip_list[$RANDOM % ${#ip_list[@]}]}

# 生成 xpanel 节点
xpanel=$(cat <<EOF
        "xpanel": {
            "ip": "$random_xpanel_ip",
            "port": 18080,
            "image": "registry.cn-hangzhou.aliyuncs.com/kunlundb/kunlun-xpanel:VERSION"
        }
EOF
)

# 生成完整的 JSON 配置文件
cat <<EOF > config.json
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

echo "配置文件已生成为 config.json"
