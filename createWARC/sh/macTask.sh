#!/usr/bin/zsh

#
# 簡易タスクランナー(MacOS, zsh)
#

#---------------------------
# 定数
#---------------------------
# 対象のディレクトリ
readonly TARGET_DIR=$(dirname $0)/warcstore

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

ipfs daemon & fswatch -0 $TARGET_DIR | while read -d '' event; do

  # ファイル名がmanabaならindexedmanaba.cdxjへ追記 
  if [[ "$event" == |manaba| ]];then
    echo "manaba"
    ipwb index $event >> indexedmanaba.cdxj
    rm ${event}
  fi

  # ファイル名がstudentならindexdestudent.cdxjへ追記 
  if [[ "$event" == |student| ]];then
    echo "student"
    ipwb index $event >> indexedstudent.cdxj
    rm ${event}
  fi

  # ファイル名がhopeならindexedhope.cdxjへ追記 
  if [[ "$event" == |hope| ]];then
    echo "hope"
    ipwb index $event >> indexedhope.cdxj
    rm ${event}
  fi

  # ファイル名がfunならindexedfun.cdxjへ追記
  if [[ "$event" == |fun| ]];then
	echo "fun"
	ipwb index $event >> indexedfun.cdxj
	rm ${event}
  fi

done