#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$ROOT"

SOURCE_IMAGE="$ROOT/Resources/background.png"
BACKGROUND="$ROOT/Resources/Images/dmg-background.png"
ICONSET_DIR="$ROOT/Generated/MonsterDeleter.iconset"
APP_ICON="$ROOT/Resources/MonsterDeleter.icns"
MODULE_CACHE="$ROOT/DerivedData/ModuleCache.noindex"
OUTPUT_DIR="$ROOT/Output"
OUTPUT="$OUTPUT_DIR/MonsterDeleter-0.1.0.dmg"
OPEN_HELPER_SOURCE="$ROOT/Scripts/open-installed-app.command"
OPEN_HELPER_NAME="安装后打开 MonsterDeleter.command"
GUIDE_SOURCE="$ROOT/Resources/安装指南.pdf"
GUIDE_NAME="安装指南.pdf"

# Remove artifacts from previous runs before starting a new release build.
rm -rf -- "$OUTPUT_DIR"
mkdir -p -- "$OUTPUT_DIR"
find "$ROOT" -maxdepth 1 -type f \
  \( -name 'MonsterDeleter-0.1.0.dmg' -o -name 'rw.*.MonsterDeleter-0.1.0.dmg' \) \
  -delete

# The DMG background is a 900x780, 50%-opacity derivative. The app icon stays opaque.
test -f "$SOURCE_IMAGE"
test -f "$GUIDE_SOURCE"
mkdir -p "$MODULE_CACHE"
CLANG_MODULE_CACHE_PATH="$MODULE_CACHE" \
  swift "$ROOT/Scripts/make-release-assets.swift" "$SOURCE_IMAGE" "$BACKGROUND" "$ICONSET_DIR"
rm -f -- "$APP_ICON"
iconutil -c icns "$ICONSET_DIR" -o "$APP_ICON"

# 构建 Release App
./Scripts/build-local.sh

APP_PATH="$ROOT/DerivedData/Build/Products/Release/MonsterDeleter.app"
STAGING_DIR="$(mktemp -d)"

trap 'rm -rf "$STAGING_DIR"' EXIT

test -d "$APP_PATH"
test -f "$BACKGROUND"

# DMG 中只需要放完整的 App Bundle
ditto "$APP_PATH" "$STAGING_DIR/MonsterDeleter.app"
ditto "$OPEN_HELPER_SOURCE" "$STAGING_DIR/$OPEN_HELPER_NAME"
ditto "$GUIDE_SOURCE" "$STAGING_DIR/$GUIDE_NAME"
chmod +x "$STAGING_DIR/$OPEN_HELPER_NAME"

create-dmg \
  --volname "MonsterDeleter" \
  --volicon "$APP_ICON" \
  --background "$BACKGROUND" \
  --window-pos 120 120 \
  --window-size 900 780 \
  --icon-size 120 \
  --icon "MonsterDeleter.app" 260 540 \
  --hide-extension "MonsterDeleter.app" \
  --app-drop-link 650 540 \
  --icon "$GUIDE_NAME" 450 130 \
  --icon "$OPEN_HELPER_NAME" 450 690 \
  --hide-extension "$OPEN_HELPER_NAME" \
  --overwrite \
  "$OUTPUT" \
  "$STAGING_DIR"

echo "DMG 已生成：$OUTPUT"
