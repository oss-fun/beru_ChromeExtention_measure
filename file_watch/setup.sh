#!/bin/sh

OS=''

#config 存在確認
if [ ! -f ./config ]; then
	echo config not found.
	touch config
fi

generate_config() {
	echo IPWB_DATA_DIR=$(pwd)/ipfs_data > ./config
	
	TARGET_DIR=''
	if [ -d "$HOME/Downloads" ]; then
		TARGET_DIR="$HOME/Downloads"
		echo "log: watch dir -> ${TARGET_DIR}" 
	else
		TARGET_DIR=$(pwd)/target
		echo log: ダウンロードフォルダーが見つかりません。手動でwarcfileをtargetフォルダーに移してください。
		if [ ! -d "${TARGET_DIR}" ]; then
			mkdir $(pwd)/target
		fi
	fi
	echo WATCH_TARGET_DIR="${TARGET_DIR}" >> ./config
}

system_check(){
	# kernel check 
	if [ "$(uname)" = 'Darwin' ]; then
		OS='Mac'
	elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
		OS='Linux'
	fi

	DOCKER_PATH=$(which docker)
	if [ -z "${DOCKER_PATH}" ]; then
		echo error: docker is not installed
		exit 1
	fi
}

generate_config
system_check
if [ -z "${OS}" ];then
	echo error: OS
	exit 1
elif [ "${OS}" = 'Linux' ]; then
	sudo apt -qq update
	sudo apt -qq install inotify-tools
	./linuxTask.sh&
elif [ "$OS" = 'Mac' ]; then
	brew install fswatch
	./macTask.sh&
fi

docker run -d --name ipfs \
	-e PRIVATE_PEER_ID="12D3KooWRdUnAXeCoW9FUnchhQsiNfvffwMYqS2nGdraUfvuqzoy" \
	-e PRIVATE_PEER_IP_ADDR="153.120.91.229"  \
	-e IPFS_SWARM_KEY_FILE=/etc/swarm.key \
	-v $(pwd)/ipfs_config/swarm.key:/etc/swarm.key \
	-v $(pwd)/ipfs_config/001-bootstrap.sh:/container-init.d/001-bootstrap.sh \
	-p 4001:4001   -p 127.0.0.1:8080:8080   -p 127.0.0.1:5001:5001 \
	ipfs/kubo | read DOCKER_ID;
	