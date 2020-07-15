#!/bin/bash

CFG_FOLDER=${1%/*}'/configs'
CFG_FILE_T=$2

sed -i "s/\(proxy_svraddr4=(\).*\()\)/\1$(cat "${CFG_FOLDER}/servers")\2/" ${CFG_FILE_T}

num=1
ports_t=''
for port in $(cat "${CFG_FOLDER}/ports")
do
	if [ ${num} -ne 1 ]
	then
		ports_t=${ports_t}','
	fi
	ports_t=${ports_t}${port}
	let num++
done

sed -i "s/\(proxy_svrport='\).*\('\)/\1${ports_t}\2/" ${CFG_FILE_T}

echo -e "Modify: COMPLETED."

ss-tproxy restart
