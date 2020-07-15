#!/bin/bash

# 请使用管理员身份运行
######################################################################################

# 订阅链接
URL='https://example.com/example'
# 配置文件绝对路径
CFG_FILE='/example/config.json'
# 端口
SSR_PORT=10808

######################################################################################

CFG_FOLDER=''

# （不在末尾填充'='的）base64url 解码
decode(){
	local code=$1
	if [ $(expr ${#code} % 4) == 2 ]
	then
		code=${code}"=="
	elif [ $(expr ${#code} % 4) == 3 ]
	then
		code=${code}"="
	fi
	echo ${code} | base64url -d
}

# 逐行输出如下格式的节点信息
# server&port&protocol&method&obfs&password&obfsparam&protoparam&remarks&group
getlink(){
	local data=$(decode $(curl -s ${URL}))
	# local data=$(decode $(cat sub))
	if [ -z "${data}" ]
	then
		return 1
	else
		local link
		for link in ${data}
		do
			if [ ${link%://*} = 'ssr' ]
			then
				local nodeinfo=$(decode ${link#*://})
				local password=${nodeinfo##*:}
					password=$(decode ${password%%/?*})
				local params=$(echo ${nodeinfo##*/?} | sed 's/\&/\n/g')
				nodeinfo=$(echo ${nodeinfo%:*} | sed 's/:/\&/g')'&'${password}
				local paramnames="obfsparam protoparam remarks group"
				local paramname
				local param
				for paramname in ${paramnames}
				do
					for param in ${params}
					do
						if [ $(echo ${param%%=*}) = ${paramname} ]
						then
							nodeinfo=${nodeinfo}'&'$(decode ${param#*=})
						fi
					done
				done
				echo ${nodeinfo}
			# elif [ ${link%://*} = 'ss' ]
			# then
			#
			# elif [ ${link:0:3} = 'MAX' ]
			# 根据一般约定，当首行为MAX=n时，客户端随机保留n条，（如果有）丢弃多余的
			# 实现麻烦，很少用到，就此略过
			#
			# else
			#
			fi
		done
	fi
	return 0
}

# 输出SSR配置
# $1: server
# $2: port
# $3: protocol
# $4: method
# $5: obfs
# $6: password
# $7: obfsparam
# $8: protoparam
# $9: remarks
# $10: group
SSRconfig(){
	local config="\
{
	\"server\": \"$1\",
	\"server_port\": $2,
	\"protocol\": \"$3\",
	\"method\": \"$4\",
	\"obfs\": \"$5\",
	\"password\": \"$6\",
	\"obfs_param\": \"$7\",
	\"protocol_param\": \"$8\",
	\"remarks\":\"$9\",
	\"group\": \"${10}\",
	\"local_address\": \"0.0.0.0\",
	\"local_port\": \"${SSR_PORT}\"
}
"
	echo "${config}"
}

OutputConfig(){
	local links=$(echo -e "${1}" | tr '\n' '^')
	local i=1
	local num=1
	local nodeinfo="$(echo "${links}" | cut -d '^' -f ${i})"
	while [ -n "${nodeinfo}" ]
	do
		local server=$(echo ${nodeinfo} | cut -d \& -f 1)
		local port=$(echo ${nodeinfo} | cut -d \& -f 2)
		local protocol=$(echo ${nodeinfo} | cut -d \& -f 3)
		local method=$(echo ${nodeinfo} | cut -d \& -f 4)
		local obfs=$(echo ${nodeinfo} | cut -d \& -f 5)
		local password=$(echo ${nodeinfo} | cut -d \& -f 6)
		local obfsparam=$(echo ${nodeinfo} | cut -d \& -f 7)
		local protoparam=$(echo ${nodeinfo} | cut -d \& -f 8)
		local remarks=$(echo ${nodeinfo} | cut -d \& -f 9)
		local group=$(echo ${nodeinfo} | cut -d \& -f 10)

		if [ ${#port} -lt 2 ] # 判断是否是用来通告信息的假节点，一般这种节点会使用10以下的端口
		then # 从中获取通告信息
			info=${info}${remarks}"\n"
		else # 输出 SSR 配置文件到配置文件目录
			echo $(SSRconfig "${server}" "${port}" "${protocol}" "${method}" "${obfs}" "${password}" "${obfsparam}" "${protoparam}" "${remarks}" "${group}") > $(echo ${CFG_FOLDER}'/config_'${num}'.json')
			num=$(expr ${num} + 1)
		fi
		
		i=$(expr ${i} + 1)
		local nodeinfo="$(echo "${links}" | cut -d '^' -f ${i})"
	done
}

init(){
	CFG_FOLDER=${CFG_FILE%/*}'/configs'
	mkdir -p ${CFG_FOLDER}
	rm -f "${CFG_FOLDER}/config_"*".json"
}

main(){
	init

	local links=$(getlink)
	if [ $? == 0 ]
	then
		echo "Download: SUCCESS."
	else
		echo "Download: FAILED."
		return
	fi

	OutputConfig "${links}"
	echo "Write: COMPLETED."
}

main
