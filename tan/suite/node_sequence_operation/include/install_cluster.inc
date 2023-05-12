#Use case description:
#1.create cluster
--connection default
--let $node_mgr_1 = query_get_value(select hostaddr from server_nodes where machine_type = "computer",hostaddr,1)
--let $node_mgr_2 = query_get_value(select hostaddr from server_nodes where machine_type = "computer",hostaddr,2)
--let $node_mgr_3 = query_get_value(select hostaddr from server_nodes where machine_type = "computer",hostaddr,3)
--let $storage_iplists="$node_mgr_1","$node_mgr_2","$node_mgr_3"

--http_connect(cluster_mgr_http1, cluster_mgr,50000)
--http
request_type: POST
header:Content-Type:application/json
body:{
        "version":"1.0",
        "job_id":"",
        "job_type":"create_cluster",
        "user_name":"super_dba",
        "timestamp":"202205131532",
        "paras":{
              "nick_name":"rbrcluster001",
              "ha_mode":"rbr",
              "shards":"1",
              "nodes":"3",
              "comps":"3",
              "max_storage_size":"20",
              "max_connections":"6",
              "cpu_cores":"8",
              "innodb_size":"1",
              "data_storage_MB":"1024",
	      "log_storage_MB":"1024",
              "dbcfg":"0",
              "fullsync_level": "1",
              "storage_iplists": [
                   "${node_mgr.1}"
                          ],
              "computer_iplists": [
                   "${node_mgr.1}"
                           ]
  }           
}
EOF

--let $job_id = `http_reap(job_id)`
--sleep 5
--source kunlun-test/suite/node_sequence_operation/include/wait_http_request_finish.inc 
--echo "$cluster_id:$cluster_name create cluster successful"
