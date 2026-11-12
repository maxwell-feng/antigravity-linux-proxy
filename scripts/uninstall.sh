#!/usr/bin/env bash
set -euo pipefail

LS_DIR="${LS_DIR:-/opt/antigravity/resources/bin}"
LS="$LS_DIR/language_server"
REAL="$LS_DIR/language_server.real"

[ "$(id -u)" -eq 0 ] || { echo "需要 root，请用 sudo 运行"; exit 1; }

if [ -f "$REAL" ]; then
  mv -f "$REAL" "$LS"
  echo "已还原 language_server，包装已移除。"
else
  echo "没有 language_server.real，可能未安装或已还原。"
fi
