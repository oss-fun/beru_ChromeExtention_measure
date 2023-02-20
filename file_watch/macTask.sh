#!/bin/bash
source ./config

sudo docker start ipwb_local

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
    cp $event $(pwd)/warc
    rm $event
    echo "WARC FILE COPY"
    sudo docker exec -i ipwb_local ipwb index /data/warc/$filename >> ./cdxj/Tenki.cdxj
  fi
done