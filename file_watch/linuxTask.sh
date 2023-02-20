#!/bin/bash
source ./config

sudo docker start ipwb_local

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
        cp -r $WATCH_TARGET_DIR/${ARR[2]} $(pwd)/warc/
        rm $WATCH_TARGET_DIR/${ARR[2]}
        echo WATCH : ${WATCH_TARGET_DIR}
        echo "WARC FILE COPY"
        sudo docker exec -i ipwb_local ipwb index /data/warc/${ARR[2]} >> ./cdxj/Tenki.cdxj
    fi
done 