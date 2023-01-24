#!/bin/sh

#config 存在確認
if [ ! -f ./config ]; then
	echo config not found.
	touch config
fi

generate_config() {
	echo 'IPWB_DATA_DIR="hogehoge"' > ./config
}

system_check(){
	echo check
	# mac or linux 
}

generate_config
