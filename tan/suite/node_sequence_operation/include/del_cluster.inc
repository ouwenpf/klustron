#Use case description:
#1.delete_cluster
#2.check delete cluster 

--connection default
--let $cluster_id_1  = query_get_value(select id from db_clusters  where status = "inuse",id,1)
--let $cluster_id_2  = query_get_value(select id from db_clusters  where status = "inuse",id,2)

--http_connect(cluster_mgr_http1, cluster_mgr,50000)
--http
request_type: POST
header:Content-Type:application/json
body:{
        "version":"1.0",
        "job_id":"",
        "job_type":"delete_cluster",
        "timestamp" : "1435749309",
        "user_name":"super_dba",
        "paras":{ "cluster_id":"${cluster_id_1}"} 
}
EOF

--let $job_id = `http_reap(job_id)`
--sleep 10
--source kunlun-test/suite/node_sequence_operation/include/wait_http_request_finish.inc 
--echo "$cluster_id:$cluster_name delete cluste successful"


