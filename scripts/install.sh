#!/usr/bin/env bash
set -euo pipefail

PROXY_TYPE="${PROXY_TYPE:-socks5}"
PROXY_ADDR="${PROXY_ADDR:-127.0.0.1:${PROXY_PORT:-7897}}"
LS_DIR="${LS_DIR:-/opt/antigravity/resources/bin}"
LS="$LS_DIR/language_server"
REAL="$LS_DIR/language_server.real"
GRAFTCP="${GRAFTCP:-/usr/local/bin/graftcp}"

[ "$(id -u)" -eq 0 ] || { echo "需要 root，请用 sudo 运行"; exit 1; }

if [ ! -x "$GRAFTCP" ]; then
  if command -v graftcp >/dev/null 2>&1; then
    GRAFTCP="$(command -v graftcp)"
  else
    echo "未找到 graftcp，尝试从源码编译..."
    command -v go >/dev/null 2>&1 || { echo "需要 go 才能编译 graftcp"; exit 1; }
    tmp="$(mktemp -d)"
    git clone --depth 1 https://github.com/hmgle/graftcp.git "$tmp/graftcp"
    make -C "$tmp/graftcp" >/dev/null
    install -m755 "$tmp/graftcp/local/graftcp" /usr/local/bin/graftcp
    GRAFTCP=/usr/local/bin/graftcp
    rm -rf "$tmp"
  fi
fi

[ -f "$LS" ] || { echo "找不到 $LS，用 LS_DIR 指定安装路径"; exit 1; }

if [ ! -f "$REAL" ]; then
  mv "$LS" "$REAL"
  echo "已备份原 language_server -> language_server.real"
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

echo "完成：$LS -> graftcp $FLAG $PROXY_ADDR"
echo "启动 Antigravity 后运行 ./scripts/check.sh 检查。"
