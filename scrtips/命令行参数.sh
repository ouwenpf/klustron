#!/bin/bash

# 默认值
hosts=()
ports=()
users=()
keys=()
files=()

# 解析命令行参数
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h) 
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                hosts+=("$1")
                shift
            done
            ;;
        -P) 
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                ports+=("$1")
                shift
            done
            ;;
        -u) 
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                users+=("$1")
                shift
            done
            ;;
        -k) 
            shift
            if [[ -z "$1" || "$1" =~ ^- ]]; then
                echo "请为 -k 参数输入一个值"
                exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                keys+=("$1")
                shift
            done
            ;;
        -f) 
            shift
            if [[ -z "$1" || "$1" =~ ^- ]]; then
                echo "请为 -f 参数输入一个值"
                exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                files+=("$1")
                shift
            done
            ;;
        -h*) 
            hosts+=("${1#-h}")
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                hosts+=("$1")
                shift
            done
            ;;
        -P*) 
            ports+=("${1#-P}")
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                ports+=("$1")
                shift
            done
            ;;
        -u*) 
            users+=("${1#-u}")
            shift
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                users+=("$1")
                shift
            done
            ;;
        -k*) 
            keys+=("${1#-k}")
            shift
            if [[ -z "$1" || "$1" =~ ^- ]]; then
                echo "请为 -k 参数输入一个值"
                exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                keys+=("$1")
                shift
            done
            ;;
        -f*) 
            files+=("${1#-f}")
            shift
            if [[ -z "$1" || "$1" =~ ^- ]]; then
                echo "请为 -f 参数输入一个值"
                exit 1
            fi
            while [[ "$#" -gt 0 && ! "$1" =~ ^- ]]; do
                files+=("$1")
                shift
            done
            ;;
        *) 
            echo "未知参数: $1"
            exit 1
            ;;
    esac
done

# 检查必填参数
if [[ ${#hosts[@]} -eq 0 ]];then
	echo "请提供 -h <host1> [<host2> ...]参数"
	exit 1
elif [[ ${#ports[@]} -eq 0 ]];then
	echo "请提供 -P <port1> [<port2> ...]参数"
	exit 1
elif [[ ${#users[@]} -eq 0 ]];then
    echo "请提供-u <user1> [<user2> ...] 参数"
    exit 1
fi

# 检查文件是否存在
all_files_exist=true
for file in "${files[@]}"; do
    if [[ ! -e "$file" ]]; then
        echo "文件不存在: $file"
        all_files_exist=false
    fi
done

# 如果有文件不存在，退出
if [[ "$all_files_exist" == false ]]; then
    exit 1
fi



# 函数举例
function hosts_params(){

	    input_parameter=$@
		echo "主机: ${input_parameter[@]}"


}


function ports_params(){

	    input_parameter=$@
		echo "端口: ${input_parameter[@]}" 

}


function users_params(){

	    input_parameter=$@
		echo "用户: ${input_parameter[@]}"

}





if [[ "${#hosts[@]}" -gt 0 ]]; then
    hosts_params "${hosts[@]}"
fi

if [[ "${#ports[@]}" -gt 0 ]]; then
    ports_params "${ports[@]}"
fi

if [[ "${#users[@]}" -gt 0 ]]; then
    users_params "${users[@]}"
fi






#echo "主机: ${hosts[*]}"
#echo "端口: ${ports[*]}"
#echo "用户: ${users[*]}"
#[[ ${#keys[@]} -gt 0 ]] && echo "密钥: ${keys[*]}"
#[[ ${#files[@]} -gt 0 ]] && echo "文件: ${files[*]}"
