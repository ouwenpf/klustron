#!/bin/bash

# 显示帮助信息
usage() {
  echo "Usage: $0 [-y|-m|-d] table_name"
  echo "  -y  Generate yearly partitions"
  echo "  -m  Generate monthly partitions"
  echo "  -d  Generate daily partitions"
  exit 1
}

# 检查参数数量
if [ $# -ne 2 ]; then
  usage
fi

# 初始化变量
partition_type=""

# 解析参数
while getopts "ymd" opt; do
  case $opt in
    y)
      partition_type="yearly"
      ;;
    m)
      partition_type="monthly"
      ;;
    d)
      partition_type="daily"
      ;;
    *)
      usage
      ;;
  esac
done

# 如果没有设置分区类型，显示帮助信息并退出
if [ -z "$partition_type" ]; then
  usage
fi

# 获取表名
shift $((OPTIND - 1))
base_table_name=$1

# 验证日期格式是否正确
validate_date() {
  if ! date -d "$1" >/dev/null 2>&1; then
    echo "Error: Invalid date format. Please use YYYY-MM-DD format." >&2
    exit 1
  fi
}

# 设置起始和结束日期
start_date='2020-01-01'
end_date='2021-12-01'

# 验证起始和结束日期格式
validate_date "$start_date"
validate_date "$end_date"
shard=(1 2 3)

# 计算分区数量
# if [ "$partition_type" == "yearly" ]; then
  # num_partitions=$(($(date -d "$end_date" +%Y) - $(date -d "$start_date" +%Y) + 1))
# elif [ "$partition_type" == "monthly" ]; then
# num_partitions=$((($(date -d "$end_date" +%Y) - $(date -d "$start_date" +%Y)) * 12 + \
                  # 10#$(date -d "$end_date" +%m) - 10#$(date -d "$start_date" +%m) ))

# elif [ "$partition_type" == "daily" ]; then
  # num_partitions=$((($(date -d "$end_date" +%s) - $(date -d "$start_date" +%s)) / (60*60*24) + 1))
# fi

# 循环生成指定数量的分区表并将 SQL 输出到文件
# for i in $(seq 0 $((num_partitions - 1))); do
    # partition_number=$((i % num_partitions))
    # shard_index=$((i % ${#shard[@]}))
    # shard_number=${shard[shard_index]}
# done


# 生成第一个分区表SQL语句（适用于起始时间前的数据）
first_partition_table_name="${base_table_name}_p$(date -d "$start_date" +%Y%m)"
first_partition_sql="CREATE TABLE \"${first_partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM (MINVALUE) TO ('$start_date');"


# 输出第一个分区表SQL语句
echo "${first_partition_sql}"

if [ "$partition_type" == "yearly" ]; then
  # 按年生成分区表
  
  
  current_year=$(date -d "$start_date" +%Y)
  while [ "$current_year" -lt "$(date -d "$end_date" +%Y)" ]; do
    shard_index=$(($current_year % ${#shard[@]}))
    shard_number=${shard[shard_index]}
    next_year=$((current_year + 1))
    partition_table_name="${base_table_name}_p${next_year}${start_date:5:2}"

    # 生成分区表SQL语句
sql="CREATE TABLE \"${partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('${current_year}-${start_date:5:5}') TO ('${next_year}-${start_date:5:5}') WITH (shard = ${shard_number}) ;"

    # 输出SQL语句
    echo "${sql}"

    # 更新当前年份
    current_year=$next_year
  done

  # 输出最后一个分区表SQL语句
  last_partition_table_name="${base_table_name}_p$(date -d "$end_date" +%Y%m)"
  last_partition_sql="CREATE TABLE \"${last_partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('$end_date') TO (MAXVALUE);"
  echo "${last_partition_sql}"
  
  
  
elif [ "$partition_type" == "monthly" ]; then
  # 按月生成分区表
  current_date="$start_date"
  while [ "$(date -d "$current_date" +%Y%m)" != "$(date -d "$end_date" +%Y%m)" ]; do
    shard_index=$(($(date -d "$current_date" +%Y%m%d) % ${#shard[@]}))
    shard_number=${shard[shard_index]}
    next_date=$(date -d "$current_date +1 month" +%Y-%m-%d)
    partition_table_name="${base_table_name}_p$(date -d "$current_date +1 month" +%Y%m%d)"

    # 生成分区表SQL语句
    sql="CREATE TABLE \"${partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('$current_date') TO ('$next_date') WITH (shard = ${shard_number});"

    # 输出SQL语句
    echo "${sql}"

    # 更新当前日期
    current_date="$next_date"
  done

  # 输出最后一个分区表SQL语句
  last_partition_table_name="${base_table_name}_p$(date -d "$end_date +1 month" +%Y%m%d)"
  last_partition_sql="CREATE TABLE \"${last_partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('$end_date') TO (MAXVALUE);"
  echo "${last_partition_sql}"

elif [ "$partition_type" == "daily" ]; then
  # 按天生成分区表
  current_date="$start_date"
  while [ "$(date -d "$current_date" +%Y%m%d)" != "$(date -d "$end_date" +%Y%m%d)" ]; do
    shard_index=$(($(date -d "$current_date" +%Y%m%d) % ${#shard[@]}))
    shard_number=${shard[shard_index]}
    next_date=$(date -d "$current_date +1 day" +%Y-%m-%d)
    partition_table_name="${base_table_name}_p$(date -d "$current_date +1 day" +%Y%m%d)"

    # 生成分区表SQL语句
    sql="CREATE TABLE \"${partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('$current_date') TO ('$next_date') WITH (shard = ${shard_number});"

    # 输出SQL语句
    echo "${sql}"

    # 更新当前日期
    current_date="$next_date"
  done

  # 输出最后一个分区表SQL语句
  last_partition_table_name="${base_table_name}_p$(date -d "$end_date +1 day" +%Y%m%d)"
  last_partition_sql="CREATE TABLE \"${last_partition_table_name}\" PARTITION OF \"${base_table_name}\"
FOR VALUES FROM ('$end_date') TO (MAXVALUE);"
  echo "${last_partition_sql}"
fi




