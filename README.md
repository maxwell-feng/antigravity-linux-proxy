# antigravity-linux-proxy

**English** | [简体中文](README-zh.md)

Force the Antigravity backend on Linux (App / IDE) through a local proxy, fixing the OAuth token-exchange timeout when logging in.

## Problem

Antigravity's UI works fine behind a proxy, but its backend `language_server` (a Go program) connects directly to `oauth2.googleapis.com` when exchanging the OAuth token and ignores `HTTP(S)_PROXY`. On a censored network this shows up as a login failure:

```
Post "https://oauth2.googleapis.com/token": dial tcp <IP>:443: i/o timeout
```

The usual tricks don't catch it: `--proxy-server`, `HTTP(S)_PROXY`, `proxychains` / `LD_PRELOAD`. The reason is that Go makes the syscall directly and never calls libc `connect()`, so those hooks miss it.

## Approach

Wrap `language_server` with [graftcp](https://github.com/hmgle/graftcp). graftcp uses `ptrace` to intercept the `connect` syscall; it is language-agnostic, so Go processes get proxied too.

```
Antigravity -> language_server(wrapper) -> graftcp -> SOCKS5(127.0.0.1:7897) -> Google
```

Only the Antigravity backend is proxied. No system-wide routing change, no TUN.

## Compatibility and versions

| Product | Version | Status |
|---|---|---|
| Antigravity App (desktop / hub) | 2.31.2 | Tested (Linux x86_64, `language_server` 2.31.2) |
| Antigravity IDE (standalone, VS Code fork, core 1.107.0) | 2.6.0 | Tested: `install-ide.sh` wraps the whole process tree with graftcp |
| Antigravity CLI (`agy`) | 1.5.5 | Not covered by these scripts; `agy` is a separate program and needs its own graftcp wrapper |

- OS: Linux, x86_64 / arm64
- Proxy: local SOCKS5 or HTTP, default `127.0.0.1:7897`

Notes:

- Tested against the Linux desktop package `Antigravity.tar.gz` (internal name `antigravity`, version **2.31.2**).
- Antigravity IDE **2.6.0** (VS Code core 1.107.0) uses `~/.gemini/bin/agy` as its backend (Go; it connects directly when exchanging the OAuth token). Its `--hub` mode self-daemonizes, so wrapping `agy` alone loses the trace. `install-ide.sh` instead hands the **whole IDE process tree** to graftcp (the `agy` daemon is traced too) without touching `agy` itself, so checks/updates of `agy` are unaffected.
- Antigravity CLI's `agy` is not at the app's `language_server` path; these scripts don't cover it.

## Install

Requires `gcc`, `make`, `git`, `go` (to build graftcp).

```bash
git clone https://github.com/maxwell-feng/antigravity-linux-proxy.git
cd antigravity-linux-proxy
sudo ./scripts/install.sh        # Antigravity App (desktop)
sudo ./scripts/install-ide.sh    # Antigravity IDE (VS Code fork)
```

See [docs/INSTALL.md](docs/INSTALL.md) for details.

## Usage

After installing, launch Antigravity from the app menu and sign in with Google as usual.

```bash
./scripts/check.sh              # status and connectivity
sudo PROXY_PORT=7890 ./scripts/install.sh   # change port
sudo ./scripts/repatch.sh       # re-wrap after an App update
sudo ./scripts/install-ide.sh   # install for Antigravity IDE
sudo ./scripts/uninstall-ide.sh # revert IDE
sudo ./scripts/uninstall.sh     # revert App
```

See [docs/USAGE.md](docs/USAGE.md) for details.

## Verify

`./scripts/check.sh` checks the wrapper, graftcp, ptrace, and proxy connectivity to `oauth2.googleapis.com`.
You can also try a Go program that dials `oauth2.googleapis.com:443` directly: it times out bare, but works under `graftcp --socks5 127.0.0.1:7897`.

## Limitations

- An Antigravity auto-update rebuilds `language_server`, which drops the wrapper; run `repatch.sh` again.
- graftcp proxies TCP only by default and ignores localhost; that's enough for login and chat.
- Requires ptrace; on most distros `ptrace_scope=1` still allows a parent to trace its child.
- Linux only. Windows uses a DLL-injection approach; macOS is not covered.

## Layout

```
scripts/install.sh         Antigravity App: prepare graftcp, wrap language_server
scripts/repatch.sh         re-wrap after an App update
scripts/install-ide.sh     Antigravity IDE: launch the whole tree via graftcp
scripts/uninstall-ide.sh   IDE: revert
scripts/check.sh           health check
scripts/uninstall.sh       App: revert
```

## License

This repository is MIT. graftcp is GPL-3.0; fetch it from its own repository.
