# antigravity-linux-proxy

给 Linux 版 Antigravity（App / IDE）的后端强制走本地代理，修复登录时 OAuth 换令牌直连超时。

## 问题

Antigravity 的界面能正常挂在代理后面，但后端 `language_server`（Go 程序）在换 OAuth 令牌时会直连 `oauth2.googleapis.com`，不读 `HTTP(S)_PROXY`。被墙的网络里表现为登录失败：

```
Post "https://oauth2.googleapis.com/token": dial tcp <IP>:443: i/o timeout
```

常见的办法都拦不住它：`--proxy-server`、`HTTP(S)_PROXY`、`proxychains` / `LD_PRELOAD`。
原因是 Go 直接发系统调用，不经过 libc 的 `connect()`，所以这些 hook 抓不到。

## 做法

用 [graftcp](https://github.com/hmgle/graftcp) 包裹 `language_server`。
graftcp 用 `ptrace` 拦截 `connect` 系统调用，与语言无关，Go 进程也能被代理。

```
Antigravity -> language_server(包装) -> graftcp -> SOCKS5(127.0.0.1:7897) -> Google
```

只代理 Antigravity 的后端进程，不改系统全局路由，不需要 TUN。

## 适用与版本

| 产品 | 版本 | 情况 |
|---|---|---|
| Antigravity App（桌面 / hub） | 2.31.2 | 已实测（Linux x86_64，`language_server` 2.31.2） |
| Antigravity IDE（独立版，VS Code 二开，内核 1.107.0） | 2.6.0 | 已实测：用 `install-ide.sh` 整包走 graftcp |
| Antigravity CLI（`agy`） | 1.5.5 | 本脚本不适用；`agy` 是独立程序，需单独用 graftcp 包装 |

- 系统：Linux，x86_64 / arm64
- 代理：本地 SOCKS5 或 HTTP，默认 `127.0.0.1:7897`

说明：

- 实测对象是 Linux 桌面包 `Antigravity.tar.gz`，产品内部名 `antigravity`，版本 **2.31.2**。
- Antigravity IDE **2.6.0**（VS Code 内核 1.107.0）的后端是 `~/.gemini/bin/agy`（Go，换 OAuth 令牌时会直连）。它 `--hub` 会自我 daemon 化，单包 agy 追不住；改用 `install-ide.sh` 把**整个 IDE 进程树**交给 graftcp（agy 守护进程会被一并追踪），不改 agy 本体，不受其校验/更新影响。
- Antigravity CLI 的 `agy` 不在应用的 `language_server` 路径下，本仓库脚本不覆盖。

## 安装

需要 `gcc`、`make`、`git`、`go`（编译 graftcp 用）。

```bash
git clone https://github.com/maxwell-feng/antigravity-linux-proxy.git
cd antigravity-linux-proxy
sudo ./scripts/install.sh        # Antigravity App（桌面）
sudo ./scripts/install-ide.sh    # Antigravity IDE（VS Code 二开）
```

细节见 [docs/INSTALL.md](docs/INSTALL.md)。

## 使用

装好后从应用菜单启动 Antigravity，正常走 Google 登录即可。

```bash
./scripts/check.sh              # 状态与连通性
sudo PROXY_PORT=7890 ./scripts/install.sh   # 换端口
sudo ./scripts/repatch.sh       # App 升级后重新包装
sudo ./scripts/install-ide.sh   # 装到 Antigravity IDE
sudo ./scripts/uninstall-ide.sh # IDE 还原
sudo ./scripts/uninstall.sh     # App 还原
```

细节见 [docs/USAGE.md](docs/USAGE.md)。

## 验证

`./scripts/check.sh` 会检查包装、graftcp、ptrace 以及代理到 `oauth2.googleapis.com` 的连通性。
也可以用一个 Go 程序直连 `oauth2.googleapis.com:443`：裸跑超时，套 `graftcp --socks5 127.0.0.1:7897` 能通。

## 限制

- Antigravity 自动更新会重建 `language_server`，包装会失效，跑一次 `repatch.sh`。
- graftcp 默认只代理 TCP、忽略 localhost，登录和对话够用。
- 依赖 ptrace；多数发行版 `ptrace_scope=1`，父进程 trace 子进程可用。
- 只做 Linux。Windows 用 DLL 注入方案，macOS 未覆盖。

## 目录

```
scripts/install.sh         Antigravity App：准备 graftcp，包装 language_server
scripts/repatch.sh         App 升级后重新包装
scripts/install-ide.sh     Antigravity IDE：整包经 graftcp 启动
scripts/uninstall-ide.sh   IDE：还原
scripts/check.sh           体检
scripts/uninstall.sh       App：还原
```

## 许可

本仓库 MIT。graftcp 为 GPL-3.0，从其官方仓库单独获取。
