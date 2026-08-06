#!/bin/zsh

set -euo pipefail

if [[ "${1:-}" != "--acknowledge-unlicensed-assets" ]]; then
  print -u2 -- "上游媒体没有开源许可证，不能视为可自由再分发或商业使用。"
  print -u2 -- "确认已阅读 THIRD_PARTY_NOTICES.md 后，请使用："
  print -u2 -- "  $0 --acknowledge-unlicensed-assets"
  exit 2
fi

script_dir=${0:A:h}
project_dir=${script_dir:h}
asset_import_dir=$(mktemp -d /tmp/monsterdeleter-assets.XXXXXX)

cleanup() {
  case "$asset_import_dir" in
    /tmp/monsterdeleter-assets.*) rm -rf -- "$asset_import_dir" ;;
  esac
}
trap cleanup EXIT

git clone --depth 1 https://github.com/531149627/MonsterDeleter.git "$asset_import_dir/upstream"

image_dir="$project_dir/Resources/Images"
audio_dir="$project_dir/Resources/Audio"
mkdir -p "$image_dir" "$audio_dir"

cp "$asset_import_dir/upstream/assets/走路动效_spritesheet_transparent.png" "$image_dir/walk.png"
cp "$asset_import_dir/upstream/assets/指着文件_spritesheet_transparent.png" "$image_dir/point.png"
cp "$asset_import_dir/upstream/assets/踹文件动效_spritesheet_transparent.png" "$image_dir/kick.png"
cp "$asset_import_dir/upstream/assets/雷欧登场_spritesheet_transparent.png" "$image_dir/leo.png"
cp "$asset_import_dir/upstream/assets/出场飞行动效_spritesheet_transparent.png" "$image_dir/fly.png"
cp "$asset_import_dir/upstream/assets/爆炸_spritesheet_transparent.png" "$image_dir/explosion.png"
cp "$asset_import_dir/upstream/assets/选择界面/选择界面.png" "$image_dir/targeting-background.png"

cp "$asset_import_dir/upstream/assets/音频/bgm(1).mp3" "$audio_dir/bgm.mp3"
cp "$asset_import_dir/upstream/assets/音频/怪兽说话.mp3" "$audio_dir/voice.mp4"
cp "$asset_import_dir/upstream/assets/音频/爆炸.MP4" "$audio_dir/explosion.mp4"

print -- "素材已导入到："
print -- "  $image_dir"
print -- "  $audio_dir"
