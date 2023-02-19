#!/bin/bash
echo "sudoはパッケージインストールのapt, brewコマンド, コンテナ作成のdockerコマンドに利用します"
echo "コンテナイメージのビルドが終わるまでしばらく時間がかかりますが、この画面を閉じないでください"
OS=''
arch=''

#config 存在確認
if [ ! -f ./config ]; then
  echo config not found.
  touch config
fi

generate_config() {
  echo IPWB_DATA_DIR=$(pwd)/ipwb-master/warc >./config

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
  echo WATCH_TARGET_DIR="${TARGET_DIR}" >>./config
}

system_check() {
  # kernel check
  if [ "$(uname)" = 'Darwin' ]; then
    OS='Mac'
  elif [ "$(expr substr $(uname -s) 1 5)" = 'Linux' ]; then
    OS='Linux'
  fi
  echo OS="${OS}" >>./config
  DOCKER_PATH=$(which docker)
  if [ -z "${DOCKER_PATH}" ]; then
    echo error: docker is not installed
    exit 1
  fi
}

get_arch() {
  arch=$(uname -m | tr '[:upper:]' '[:lower:]')
  case $arch in
  x86_64)
    arch='amd64'
    ;;
  i686)
    arch='amd32'
    ;;
  aarch64)
    arch='arm64'
    ;;
  aarch32)
    arch='arm32'
    ;;
  esac
    echo "${arch}"
}

generate_config
system_check
get_arch
if [ -z "${OS}" ];then
	echo error: OS
	exit 1
elif [ "${OS}" = 'Linux' ]; then
  echo ""
  sudo apt -qq update
  sudo apt -qq install inotify-tools
  ./linuxTask.sh &
elif [ "$OS" = 'Mac' ]; then
  brew install fswatch
  ./macTask.sh&
fi

sudo docker build -t beru/ipwb_local ./ipwb-master --build-arg ARCH=$arch

sudo docker run -d --name ipwb_local \
  -v $(pwd)/warc:/data/warc -v $(pwd)/cdxj:/data/cdxj \
  -p 4001:4001 -p 8080:8080 -p 5001:5001 -p 2016:2016 \
  beru/ipwb_local