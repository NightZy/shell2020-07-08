#!/bin/bash

# 请使用管理员身份运行
######################################################################################

# 订阅链接
URL='https://xxx.xxx/xxx'
# SSR 配置文件绝对路径
CFG_FILE='/xxx/xxx.json'
# SSR 本地端口
SSR_PORT=10808
# ss-tproxy 配置文件绝对路径
CFG_FILE_T='/xxx/xxx.conf'
# 脚本放置文件夹绝对路径，末尾无斜杠
SH_FOLDER='/xxx/xxx'

######################################################################################

CFG_FOLDER=${CFG_FILE%/*}'/configs'

if [ -n "$2" ]
then
	NUM=$2
else
	NUM=1
fi

case "$1" in
	"-p")
		"${SH_FOLDER}/parse.sh" ${URL} ${CFG_FILE} ${SSR_PORT}
		echo -e "Info:"
		cat "${CFG_FOLDER}/info"
	;;
	"-t")
		"${SH_FOLDER}/tproxy.sh" ${CFG_FILE} ${CFG_FILE_T}
	;;
	"-s")
		cp "${CFG_FOLDER}/config_${NUM}.json" ${CFG_FILE}
		echo "\nChange: COMPLETED."
		service ssr-redir restart
		echo -e "SSRrestart: COMPLETED."
	;;
	"-a")
		"${SH_FOLDER}/parse.sh" ${URL} ${CFG_FILE} ${SSR_PORT}

		"${SH_FOLDER}/tproxy.sh" ${CFG_FILE} ${CFG_FILE_T}

		cp "${CFG_FOLDER}/config_${NUM}.json" ${CFG_FILE}
		echo "\nChange: COMPLETED."
		service ssr-redir restart
		echo -e "SSRrestart: COMPLETED."

		echo -e "Info:"
		cat "${CFG_FOLDER}/info"
	;;
	*)
		echo "Unknown option: $1"
esac
