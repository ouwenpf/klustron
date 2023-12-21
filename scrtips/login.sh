#!/bin/bash

validate_ip() {
    local ip=$1
    local regex="^([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$"

    if ! [[ $ip =~ $regex ]]; then
        return 1
    fi
}

input_ip() {
    declare -a ips=()
    declare -A seen

    while true; do
        read -p "请输入服务器IP以空格分隔 (输入 'q' 或 'Q' 退出): " ip_list
        if [[ $ip_list =~ [qQ] ]]; then
            exit
        fi

        if [ -z "$ip_list" ] || [ ! "$ip_list" ]; then
            echo "输入不能为空，请重新输入。"
            continue
        fi

        IFS=' ' read -ra new_ips <<< "$ip_list"
        if [ "${#new_ips[@]}" -lt 3 ]; then
            echo "输入的IP不能少于三个，请重新输入。"
            continue
        fi

        # 使用关联数组来检查重复的IP
        local duplicate_found=false
		local duplicate_ips=()
        for element in "${new_ips[@]}"; do
            if [[ -n "${seen[$element]}" ]]; then
				duplicate_ips+=("$element")
                #echo "${duplicate_ips[@]}" IP输入重复，请重新输入。
                duplicate_found=true
                #break
            else
                seen["$element"]=1
            fi
        done

        if [ "$duplicate_found" = true ]; then
		    echo "${duplicate_ips[@]}"  IP输入重复，请重新输入。
			new_ips=()
			seen=()
            continue
        fi

        # 判断每个IP的合法性
        local invalid_ips=()
        for ip in "${new_ips[@]}"; do
            if ! validate_ip "$ip"; then
                invalid_ips+=("$ip")
            fi
        done

        if [ "${#invalid_ips[@]}" -gt 0 ]; then
            echo "输入的IP中存在非法的IP地址，请重新输入。"
            echo "非法的IP地址: ${invalid_ips[@]}"
			new_ips=()
			seen=()
            continue
        fi

        # 如果通过所有检查，将IP添加到数组中
        ips=("${new_ips[@]}")
        break
    done

    # 打印最终的IP数组
    echo "输入的IP列表:"
    printf '%s\n' "${ips[@]}"
}

input_ip
