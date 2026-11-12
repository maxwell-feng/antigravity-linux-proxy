# 使用

## 日常

1. 确认代理在运行（默认 `127.0.0.1:7897`）。
2. 从应用菜单启动 Antigravity。
3. Google 登录。

安装后 `language_server` 已被 graftcp 包裹，登录不会再出现 `oauth2.googleapis.com/token` 超时。

## 命令

```bash
# 状态与连通性
./scripts/check.sh

# 换端口（重写包装）
sudo PROXY_PORT=7890 ./scripts/install.sh

# Antigravity 更新后重新包装
sudo ./scripts/repatch.sh

# 卸载，还原原始 language_server
sudo ./scripts/uninstall.sh
```

## 回滚

```bash
sudo ./scripts/uninstall.sh
```

等价于手动还原：

```bash
sudo mv /opt/antigravity/resources/bin/language_server.real \
        /opt/antigravity/resources/bin/language_server
```

## 排查

- 启动卡住、LS 起不来：先 `./scripts/check.sh`，看 graftcp、包装脚本、端口是否正常。
- 换了代理端口没生效：重跑 `install.sh` 带上新端口。
- 登录仍超时：确认代理本身能到 Google，`graftcp --socks5 127.0.0.1:7897 curl -sI https://oauth2.googleapis.com/token`。
- 要看 graftcp 细节：在 `language_server` 包装脚本里给 graftcp 加 `--enable-debug-log`。

## Antigravity IDE

IDE 用 `/usr/local/bin/antigravity-ide-proxy` 启动（菜单「Antigravity IDE」已指向它），整棵进程树经 graftcp 走代理，`agy` 守护进程也在内。

```bash
sudo ./scripts/install-ide.sh     # 安装 / 换端口后重跑
sudo ./scripts/uninstall-ide.sh   # 还原
```
