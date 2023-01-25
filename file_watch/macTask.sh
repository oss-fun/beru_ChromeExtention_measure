#!/bin/bash
source ./config

#---------------------------
# ディレクトリの存在チェック
if [[ ! -d $WATCH_TARGET_DIR ]]; then
  echo "[error] Not Found target directory ${WATCH_TARGET_DIR}" 
  exit
fi

echo watch start
fswatch -0 --event Created $WATCH_TARGET_DIR | while read -d '' event; do
  echo $event
  if [[ $event =~ .warc$ ]];
  then
    filename=${event##*/}
    mv $event $(pwd)/ipwb-master/warc
    echo "WARC FILE COPY"
    docker exec -it ipwb_local ipwb index /data/warc/$filename >> /data/cdxj/hope.cdxj
  fi
done