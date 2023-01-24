#!/bin/zsh

#
# 簡易タスクランナー(MacOS, zsh)
#

#---------------------------
# 定数
#---------------------------
# 対象のディレクトリ
readonly TARGET_DIR=~/Downlocad

#---------------------------
# タスクランナー
#---------------------------
# ディレクトリの存在チェック
if [[ ! -d $TARGET_DIR ]]; then
  echo "[error] Not Found target directory ${TARGET_DIR}" 
  exit
fi


# ディレクトリを監視
# -d ''でスペースがくると入力終了
# eventにスペースまでの文字列が入る

echo $TARGET_DIR

fswatch -0 $TARGET_DIR | while read -d '' event; do
  
  echo $event
  docker container run -it --rm -v $(pwd)/ipwb_data:/data -p 2016:2016 oduwsdl/ipwb sh -c "ipwb index {warcfile} > /data/test.cdxj"

done