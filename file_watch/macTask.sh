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
    mv $event $(pwd)/ipwb_data
    echo "WARC FILE COPY"
    docker run -it --rm -v $(pwd)/ipwb_data:/data -p 2016:2016 oduwsdl/ipwb sh -c ipwb index $(pwd)/ipwb_data/${filename} >> cdxj_data/HopeArchive.cdxj
  fi
done