#!/usr/bin/env bash
set -uo pipefail

PROXY_TYPE="${PROXY_TYPE:-socks5}"
PROXY_ADDR="${PROXY_ADDR:-127.0.0.1:${PROXY_PORT:-7897}}"
LS_DIR="${LS_DIR:-/opt/antigravity/resources/bin}"
LS="$LS_DIR/language_server"
REAL="$LS_DIR/language_server.real"
GRAFTCP="${GRAFTCP:-/usr/local/bin/graftcp}"

if [ -x "$GRAFTCP" ]; then
  echo "graftcp: $("$GRAFTCP" --version 2>&1)"
else
  echo "graftcp: 缺失"
fi

echo "language_server: $([ -f "$LS" ] && echo 存在 || echo 缺失)"
echo "language_server.real: $([ -f "$REAL" ] && echo 存在 || echo 缺失)"

if [ -f "$LS" ]; then
  if [ "$(head -c2 "$LS" 2>/dev/null || true)" = "#!" ] && grep -q graftcp "$LS" 2>/dev/null; then
    echo "包装状态: 已包装"
  else
    echo "包装状态: 未包装，运行 install.sh 或 repatch.sh"
  fi
fi

echo "ptrace_scope: $(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || echo n/a)"

FLAG="--socks5"
[ "$PROXY_TYPE" = "http" ] && FLAG="--http_proxy"

if [ -x "$GRAFTCP" ]; then
  code="$("$GRAFTCP" "$FLAG" "$PROXY_ADDR" curl -s -o /dev/null -w '%{http_code}' --max-time 10 https://oauth2.googleapis.com/token 2>/dev/null || true)"
  echo "代理连通(oauth2.googleapis.com): HTTP ${code:-000}"
else
  echo "代理连通: 跳过（graftcp 缺失）"
fi
