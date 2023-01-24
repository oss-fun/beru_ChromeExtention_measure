#!/bin/sh

#config 存在確認
if [ ! -f ./config ]; then
	echo config not found.
	touch config
fi

generate_config() {
	echo IPWB_DATA_DIR=$(pwd)/ipfs_data > ./config
	echo WATCH_TARGET_DIR=$HOME/Downloads >> ./config
}

system_check(){
	echo check
	# mac or linux 
	if [ "$(uname)" == 'Darwin' ]; then
		OS='Mac'
		brew install fswatch
		./macTask.sh

	elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
		OS='Linux'
		apt update
		apt install inotify
		./linuxTask.sh
	fi
}

generate_config
docker run -d --name ipfs -e PRIVATE_PEER_ID="12D3KooWRdUnAXeCoW9FUnchhQsiNfvffwMYqS2nGdraUfvuqzoy" -e IPFS_SWARM_KEY=</ipfs_tools/swarm.key> -e PRIVATE_PEER_IP_ADDR="10.124.48.78"  -v $(pwd)/ipfs_tools/001-bootstrap.sh:/container-init.d/001-bootstrap.sh   -p 4001:4001   -p 127.0.0.1:8080:8080   -p 127.0.0.1:5001:5001   ipfs/kubo
system_check