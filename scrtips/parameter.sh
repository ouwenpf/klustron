#!/bin/bash

host_ip=${1:-192.168.0.185}
port_ip=${2:-47001}
db_cluster_id=${3:-1}

# 执行查询并将结果存入数组
mysql_result=$(PGPASSWORD=abc psql postgres://abc:abc@${host_ip}:${port_ip}/postgres -c "SELECT '-h' || b.hostaddr || ' -P' || b.port FROM pg_shard a JOIN pg_shard_node b ON a.id = b.shard_id WHERE a.db_cluster_id = ${db_cluster_id};" |sed '1d;2d;/rows/d;$d')
mapfile -t connections <<< "$mysql_result"


# 修改计算节点参数


PGPASSWORD=abc psql postgres://abc:abc@${host_ip}:${port_ip}/postgres << EOF 

alter system set statement_timeout=0;
alter system set mysql_read_timeout=1200;
alter system set mysql_write_timeout=1200;
alter system set lock_timeout=1200000;
alter system set log_min_duration_statement=1200000;
alter system set max_remote_insert_blocks=8192;
alter system set autovacuum=off;
alter system set enable_shard_binary_protocol=false  ;

EOF




# 循环处理数组中的连接信息(修改存储节点参数)
for connection in "${connections[@]}"; do

        mysql -uclustmgr   -pclustmgr_pwd $connection  2>/dev/null  << EOF
        set persist lock_wait_timeout=1200;
        set persist innodb_lock_wait_timeout=1200;
        set persist fullsync_timeout=1200000;
        set persist  enable_fullsync=off;
        set persist innodb_flush_log_at_trx_commit=2;
        set persist sync_binlog=0;
        set persist net_read_timeout=3600;
        set persist net_write_timeout=3600;
        set persist long_query_time=100;
        set persist max_binlog_size=1073741824;

EOF
done







