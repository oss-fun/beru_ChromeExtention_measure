call ./config
docker start ipwb_local
set pwd=%~dp0

rem ディレクトリの存在チェック
if exist $WATCH_TARGET_DIR(
  echo "[error] Not Found target directory %WATCH_TARGET_DIR%"
  exit
)

echo watch start

fswatch -0 --event Created %WATCH_TARGET_DIR% | while read -d '' set event; do
  echo %event%
  if %event% =~ .warc$(
    filename=%event%##*/
    cp %event% %pwd%/ipwb-master/warc
    rm %event%
    echo "WARC FILE COPY"
    sudo docker exec -i ipwb_local ipwb index /data/warc/%filename% >> ipwb-master/cdxj/hope.cdxj
  )
done