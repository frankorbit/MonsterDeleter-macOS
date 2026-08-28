#!/usr/bin/env bash

set -euo pipefail

APP_PATH="/Applications/MonsterDeleter.app"

if [[ ! -d "$APP_PATH" ]]; then
  printf '\n未找到 %s\n' "$APP_PATH"
  printf '请先将 MonsterDeleter.app 拖入 Applications 文件夹，再双击此文件。\n\n'
  read -r -p '按回车键关闭终端...'
  exit 1
fi

# The attribute may already be absent if the user has opened the app before.
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
open "$APP_PATH"

printf '\n已清除隔离属性并启动 MonsterDeleter。\n'
sleep 2
