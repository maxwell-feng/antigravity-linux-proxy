# 安装

## 环境

- Linux x86_64 或 arm64
- gcc、make、git
- Go 1.25+，仅用于编译 graftcp
- 已装 Antigravity 桌面版，默认路径 `/opt/antigravity`
- 本地代理可用，默认 `127.0.0.1:7897`（Clash Verge 混合端口）

> 本仓库以 Antigravity App（桌面）**2.31.2** 实测。IDE 2.6.0 与 CLI 1.5.5 的适用情况见 [README 的“适用与版本”](../README.md#适用与版本)。

检查 Go：

```bash
go version
```

没有就装，例如 Debian/Ubuntu：

```bash
sudo apt install -y golang-go
```

## 1. 编译 graftcp

```bash
git clone https://github.com/hmgle/graftcp.git /tmp/graftcp
cd /tmp/graftcp
make
sudo install -m755 local/graftcp /usr/local/bin/graftcp
graftcp --version
```

## 2. 安装本仓库

```bash
git clone https://github.com/maxwell-feng/antigravity-linux-proxy.git
cd antigravity-linux-proxy
sudo ./scripts/install.sh
```

脚本做三件事：

1. 检查 `graftcp`，没有就尝试用本机 Go 自动编译安装。
2. 首次运行把 `language_server` 备份成 `language_server.real`。
3. 写入包装脚本，之后每次启动 `language_server` 都经 graftcp。

自定义代理：

```bash
# 换端口（SOCKS5）
sudo PROXY_PORT=7890 ./scripts/install.sh

# HTTP 代理
sudo PROXY_ADDR=127.0.0.1:7890 PROXY_TYPE=http ./scripts/install.sh
```

## 3. 验证

```bash
./scripts/check.sh
```

然后启动 Antigravity，走 Google 登录。

## 升级后

Antigravity 更新会重建 `language_server`，覆盖包装。重跑：

```bash
sudo ./scripts/repatch.sh
```
