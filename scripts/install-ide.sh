#!/usr/bin/env bash
set -euo pipefail

PROXY_TYPE="${PROXY_TYPE:-socks5}"
PROXY_ADDR="${PROXY_ADDR:-127.0.0.1:${PROXY_PORT:-7897}}"
IDE_BIN="${IDE_BIN:-/opt/antigravity-ide/antigravity-ide}"
GRAFTCP="${GRAFTCP:-/usr/local/bin/graftcp}"
DESKTOP="${DESKTOP:-/usr/share/applications/antigravity-ide.desktop}"
LAUNCHER="${LAUNCHER:-/usr/local/bin/antigravity-ide-proxy}"

[ "$(id -u)" -eq 0 ] || { echo "需要 root，请用 sudo 运行"; exit 1; }
[ -x "$IDE_BIN" ] || { echo "找不到 IDE：$IDE_BIN（可用 IDE_BIN 指定）"; exit 1; }
[ -x "$GRAFTCP" ] || { echo "缺少 graftcp，先按 docs/INSTALL.md 安装"; exit 1; }

FLAG="--socks5"; SCHEME="socks5"
if [ "$PROXY_TYPE" = "http" ]; then FLAG="--http_proxy"; SCHEME="http"; fi

# 整包 IDE 交给 graftcp：agy --hub 会自我 daemon 化，只有包整棵进程树才能持续追踪它
cat > "$LAUNCHER" <<EOF
#!/bin/sh
# 由 antigravity-linux-proxy 生成：整包 IDE 经 graftcp 走本地代理
exec "$GRAFTCP" $FLAG "$PROXY_ADDR" "$IDE_BIN" \\
  --proxy-server="$SCHEME://$PROXY_ADDR" \\
  --proxy-bypass-list="127.0.0.1;localhost;::1" \\
  --disable-quic "\$@"
EOF
chmod 755 "$LAUNCHER"

if [ -f "$DESKTOP" ]; then
  [ -f "$DESKTOP.orig" ] || cp -a "$DESKTOP" "$DESKTOP.orig"
  python3 - "$DESKTOP" "$LAUNCHER" <<'PY'
import re, sys
p, launcher = sys.argv[1], sys.argv[2]
s = open(p, encoding='utf-8').read()
s = re.sub(r'^Exec=.*$', 'Exec=%s %%F' % launcher, s, flags=re.M)
open(p, 'w', encoding='utf-8').write(s)
PY
  update-desktop-database "$(dirname "$DESKTOP")" >/dev/null 2>&1 || true
  echo "已更新菜单入口：$DESKTOP（原文件 $DESKTOP.orig）"
else
  echo "未找到 $DESKTOP；已生成 $LAUNCHER，可手动把菜单 Exec 指向它"
fi

echo "完成：Antigravity IDE 经 graftcp $FLAG $PROXY_ADDR 启动"
