#!/usr/bin/env bash
set -euo pipefail

PROXY_TYPE="${PROXY_TYPE:-socks5}"
PROXY_ADDR="${PROXY_ADDR:-127.0.0.1:${PROXY_PORT:-7897}}"
LS_DIR="${LS_DIR:-/opt/antigravity/resources/bin}"
LS="$LS_DIR/language_server"
REAL="$LS_DIR/language_server.real"
GRAFTCP="${GRAFTCP:-/usr/local/bin/graftcp}"

[ "$(id -u)" -eq 0 ] || { echo "需要 root，请用 sudo 运行"; exit 1; }

# Antigravity 更新会把 language_server 换回原始二进制（没有 #! 头）。检测到就备份为新 REAL。
if [ -f "$LS" ] && [ "$(head -c2 "$LS" 2>/dev/null || true)" != "#!" ]; then
  mv -f "$LS" "$REAL"
  echo "检测到更新：已用新二进制覆盖 language_server.real"
fi

FLAG="--socks5"
[ "$PROXY_TYPE" = "http" ] && FLAG="--http_proxy"

cat > "$LS" <<EOF
#!/bin/sh
# 由 antigravity-linux-proxy 生成：language_server 经 graftcp 走本地代理
REAL="$REAL"
if [ -x "$GRAFTCP" ]; then
  exec "$GRAFTCP" $FLAG "$PROXY_ADDR" "\$REAL" "\$@"
else
  exec "\$REAL" "\$@"
fi
EOF
chmod 755 "$LS"

echo "已重新包装：$LS -> graftcp $FLAG $PROXY_ADDR"
