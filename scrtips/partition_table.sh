#!/bin/bash

# 表名
table_name=${1:-table}

# 输出文件
output_file="partition_${table_name}.sql"

# 分区数量，可根据需要修改
num_partitions=90

# shard 数组
# select  name,id from  pg_shard  where db_cluster_id=1;
shard_array=(1 2 3)

# 删除已存在的输出文件
rm -f "${output_file}"

table_structure="CREATE TABLE ....."

<<!
# 生成表结构的 SQL
table_structure="
CREATE TABLE ${table_name} (
    id bigint NOT NULL,
    time varchar(30) DEFAULT NULL,
    time_type varchar(30) DEFAULT NULL,
    category_id int DEFAULT NULL,
    product_id int DEFAULT NULL,
    sales_volume int DEFAULT NULL,
    volume_month_growth double DEFAULT NULL,
    sales double DEFAULT NULL,
    sales_month_growth double DEFAULT NULL,
    sales_volume_kg double DEFAULT NULL,
    sales_volume_kg_month_growth double DEFAULT NULL,
    control_platform int DEFAULT NULL,
    CONSTRAINT ap_category_platform_product_uper_pkey PRIMARY KEY (id)
) PARTITION BY HASH(id);

ALTER TABLE ${table_name} ALTER COLUMN id ADD AUTO_INCREMENT;
"
!

# 将表结构输出到文件
echo "${table_structure}" >> "${output_file}"

# 循环生成指定数量的分区表并将 SQL 输出到文件
for i in $(seq 0 $((num_partitions - 1))); do
	    partition_number=$((i % num_partitions))
	        shard_index=$((i % ${#shard_array[@]}))
		    shard_number=${shard_array[${shard_index}]}

		        # 生成分区表的 SQL
			    partition_sql="CREATE TABLE ${table_name}_part_${i} PARTITION OF ${table_name} FOR VALUES WITH (MODULUS ${num_partitions}, REMAINDER ${partition_number}) WITH (shard = ${shard_number});"

			        # 输出 SQL 到文件
				    echo "${partition_sql}" >> "${output_file}"
			    done

			    echo "SQL scripts generated and saved to ${output_file}"
