#!/bin/bash

source ./config


TARGET_DIR=$(cd $(dirname $0) && pwd)

echo watch start
inotifywait -m $WATCH_TARGET_DIR -mq $dir_name -e create | while read line; do

    ARR=(${line})
    targetFile=${ARR[2]} 

    if [[ ${targetFile} =~ .warc$ ]];
    then
        echo "${targetFile} ipwb index"
        docker run -it --rm \
					-v $(pwd)/ipwb_data:/data \
					-p 2016:2016 oduwsdl/ipwb \
					sh -c "ipwb index > /data/test.cdxj"
        rm ${ARR[2]}
    fi

done 
