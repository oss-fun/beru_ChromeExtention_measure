#!/bin/bash

source ./config

TARGET_DIR=$(cd $(dirname $0) && pwd)
ipfs daemon

inotifywait -m $WATCH_TARGET_DIR -mq $dir_name -e create | while read line; do

    ARR=(${line})
    targetFile=${ARR[2]} 

    if [[ ${targetFile} =~ warc$ ]];
    then
        echo "${targetFile} ipwb index"
        ipwb index ${ARR[2]} >> hopeArchive.cdxj
        rm ${ARR[2]}
    fi

done 