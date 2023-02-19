echo "コンテナイメージのビルドが終わるまでしばらく時間がかかりますが、この画面を閉じないでください"

winget install fswatch
winget install Docker.DockerDesktop

set OS='windows'
set arch=''
set pwd=%~dp0

rem config存在確認
if not exist ./config (
  echo "config not found."
  type nul > config
)

:generate_config
  echo IPWB_DATA_DIR=%pwd%/ipwb-master/warc >./config
  set TARGET_DIR=''
  if exist %HOME%/Downloads(
    TARGET_DIR="%HOME%/Downloads"
    echo "log: watch dir -> %TARGET_DIR%"
  )
  else(
    TARGET_DIR=%pwd%/target
    echo log: ダウンロードフォルダーが見つかりません。手動でwarcfileをtargetフォルダーに移してください。
    if not exist TARGET_DIR
      mkdir %pwd%/target
    fi
  )
  echo WATCH_TARGET_DIR=%TARGET_DIR% >>./config
exit /b

:get_arch
  if %PROCESSOR_ARCHITECTURE% EQU "x86"(
    set arch=32
  )
  else(
    set arch=64
  )
exit /b

call generate_config
call get_arch
call winTask.bat

docker build -t beru/ipwb_local ./ipwb-master --build-arg ARCH=$arch

docker run -d --name ipwb_local \
  -v $(pwd)/warc:/data/warc -v $(pwd)/cdxj:/data/cdxj \
  -p 4001:4001 -p 8080:8080 -p 5001:5001 -p 2016:2016 \
  beru/ipwb_local