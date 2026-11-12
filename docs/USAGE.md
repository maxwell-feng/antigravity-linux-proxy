# Usage

[English](USAGE.md) | [简体中文](USAGE-zh.md)

## Daily use

1. Make sure the proxy is running (default `127.0.0.1:7897`).
2. Launch Antigravity from the app menu.
3. Sign in with Google.

After installation `language_server` is wrapped by graftcp, so login no longer fails with the `oauth2.googleapis.com/token` timeout.

## Commands

```bash
# status and connectivity
./scripts/check.sh

# change port (rewrites the wrapper)
sudo PROXY_PORT=7890 ./scripts/install.sh

# re-wrap after an Antigravity update
sudo ./scripts/repatch.sh

# uninstall, restore the original language_server
sudo ./scripts/uninstall.sh
```

## Rollback

```bash
sudo ./scripts/uninstall.sh
```

Equivalent to restoring manually:

```bash
sudo mv /opt/antigravity/resources/bin/language_server.real \
        /opt/antigravity/resources/bin/language_server
```

## Troubleshooting

- Startup hangs or the LS won't start: run `./scripts/check.sh` and check graftcp, the wrapper, and the port.
- Changed the proxy port but nothing happened: re-run `install.sh` with the new port.
- Login still times out: make sure the proxy itself can reach Google, `graftcp --socks5 127.0.0.1:7897 curl -sI https://oauth2.googleapis.com/token`.
- Want graftcp details: add `--enable-debug-log` to graftcp in the `language_server` wrapper.

## Antigravity IDE

The IDE launches via `/usr/local/bin/antigravity-ide-proxy` (the "Antigravity IDE" menu entry points to it); the whole process tree goes through graftcp, including the `agy` daemon.

```bash
sudo ./scripts/install-ide.sh     # install / re-run after changing port
sudo ./scripts/uninstall-ide.sh   # revert
```
