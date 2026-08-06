#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
derived_data="$project_dir/DerivedData"

cd "$project_dir"
xcodegen generate
xcodebuild \
  -project MonsterDeleter.xcodeproj \
  -scheme MonsterDeleter \
  -configuration Release \
  -derivedDataPath "$derived_data" \
  CODE_SIGNING_ALLOWED=NO \
  build

app_path="$derived_data/Build/Products/Release/MonsterDeleter.app"
extension_path="$app_path/Contents/PlugIns/MonsterDeleterFinderSync.appex"

codesign --force --sign - "$extension_path"
codesign --force --deep --sign - "$app_path"

print -r -- "$app_path"
