# Installation

[English](INSTALL.md) | [简体中文](INSTALL-zh.md)

## Requirements

- Linux x86_64 or arm64
- gcc, make, git
- Go 1.25+ (only to build graftcp)
- Antigravity desktop installed, default path `/opt/antigravity`
- A local proxy, default `127.0.0.1:7897` (Clash Verge mixed port)

> Tested on Antigravity App (desktop) **2.31.2**. See "Compatibility and versions" in the [README](../README.md#compatibility-and-versions) for IDE 2.6.0 and CLI 1.5.5.

Check Go:

```bash
go version
```

If it's missing, install it, e.g. on Debian/Ubuntu:

```bash
sudo apt install -y golang-go
```

## 1. Build graftcp

```bash
git clone https://github.com/hmgle/graftcp.git /tmp/graftcp
cd /tmp/graftcp
make
sudo install -m755 local/graftcp /usr/local/bin/graftcp
graftcp --version
```

## 2. Install this repo

```bash
git clone https://github.com/maxwell-feng/antigravity-linux-proxy.git
cd antigravity-linux-proxy
sudo ./scripts/install.sh
```

The script does three things:

1. Checks for `graftcp`; if missing, builds and installs it with the local Go.
2. On first run, backs up `language_server` to `language_server.real`.
3. Writes a wrapper so every `language_server` start goes through graftcp.

Custom proxy:

```bash
# change port (SOCKS5)
sudo PROXY_PORT=7890 ./scripts/install.sh

# HTTP proxy
sudo PROXY_ADDR=127.0.0.1:7890 PROXY_TYPE=http ./scripts/install.sh
```

## 3. Verify

```bash
./scripts/check.sh
```

Then launch Antigravity and sign in with Google.

## After an update

An Antigravity update rebuilds `language_server` and overwrites the wrapper. Re-run:

```bash
sudo ./scripts/repatch.sh
```

## Install for Antigravity IDE

Antigravity IDE (VS Code fork, 2.6.0 / core 1.107.0) uses `~/.gemini/bin/agy` as its backend, and `--hub` self-daemonizes. Don't modify `agy`; wrap the whole process tree with graftcp instead:

```bash
sudo ./scripts/install-ide.sh
```

The script generates `/usr/local/bin/antigravity-ide-proxy` (wrapping `/opt/antigravity-ide/antigravity-ide` with graftcp) and points the menu entry `antigravity-ide.desktop` `Exec` to it (the original is backed up as `.orig`). The IDE's `agy` daemon is traced by graftcp as well.

If the default path is not `/opt/antigravity-ide/antigravity-ide`, set `IDE_BIN`.

Revert:

```bash
sudo ./scripts/uninstall-ide.sh
```
