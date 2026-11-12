#!/usr/bin/env bash
set -euo pipefail

DESKTOP="${DESKTOP:-/usr/share/applications/antigravity-ide.desktop}"
LAUNCHER="${LAUNCHER:-/usr/local/bin/antigravity-ide-proxy}"

[ "$(id -u)" -eq 0 ] || { echo "需要 root，请用 sudo 运行"; exit 1; }

if [ -f "$DESKTOP.orig" ]; then
  mv -f "$DESKTOP.orig" "$DESKTOP"
  update-desktop-database "$(dirname "$DESKTOP")" >/dev/null 2>&1 || true
  echo "已还原菜单入口：$DESKTOP"
fi
rm -f "$LAUNCHER"
echo "已删除启动器：$LAUNCHER"
