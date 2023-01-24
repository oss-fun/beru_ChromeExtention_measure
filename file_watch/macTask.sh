#!/bin/bash
source ./config

#---------------------------
# ディレクトリの存在チェック
if [[ ! -d $WATCH_TARGET_DIR ]]; then
  echo "[error] Not Found target directory ${WATCH_TARGET_DIR}" 
  exit
fi

echo watch start
fswatch -0 $WATCH_TARGET_DIR | while read -d '' event; do
  
  if [[ $event =~ warc$ ]];
  then
    echo $event
    mv $event $(pwd)/ipwb_data
    docker container run -it --rm -v $(pwd)/ipwb_data:/data -p 2016:2016 oduwsdl/ipwb sh -c "ipwb index > /data/test.cdxj"
  fi
done