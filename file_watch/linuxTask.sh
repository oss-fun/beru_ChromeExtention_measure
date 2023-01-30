#!/bin/bash
source ./config

docker start ipwb_local

# ディレクトリの存在チェック
if [[ ! -d $WATCH_TARGET_DIR ]]; then
    echo "[error] Not Found target directory ${WATCH_TARGET_DIR}"
    exit
fi

echo watch start
inotifywait -m $WATCH_TARGET_DIR -mq $dir_name -e create | while read event; do
    ARR=(${event})
    targetFile=${ARR[2]}
    if [[ ${targetFile} =~ .warc$ ]];then
        filename=${event##*/}
        cp $event $(pwd)/ipwb-master/warc
        rm ${WATCH_TARGET_DIR}/${ARR[2]}
        echo ${WATCH_TARGET_DIR}/
        echo "WARC FILE COPY"
        docker exec -it ipwb_local ipwb index /data/warc/$filename >> ipwb_master/cdxj
    fi
done 