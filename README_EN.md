# cc-switch-sync

Companion scripts for [CC Switch](https://github.com/farion1231/cc-switch) — double-click to push your local Claude and Codex AI provider config to remote Linux servers.

[中文](README.md)

## One-time setup

1. Install [CC Switch](https://github.com/farion1231/cc-switch/releases), add a Provider (API Key + Base URL) in the GUI, and disable `enableLocalProxy` in Settings
2. To sync Codex, make sure `%USERPROFILE%\.codex\config.toml` and `%USERPROFILE%\.codex\auth.json` work locally first
3. Copy `servers.conf.example` to `servers.conf` and fill in your server details

## Usage

Double-click a script to run it:

| Script | What it does |
|--------|--------------|
| `1. SSH Connect.bat` | Connect to a server. First time: pick "+ Add new server" and the script will automatically initialize the remote environment (proxy, workdir, Claude/Codex config), then connect |
| `2. Sync Config.bat` | After switching Provider in CC Switch or Codex, push the new config to the server |

Codex sync overwrites remote `~/.codex/config.toml` after creating `config.toml.bak.<timestamp>`. If local `auth.json` exists, it is synced too and backed up before replacement.

## `servers.conf` format

```
Host my-server
  HostName 10.0.0.1
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.0.0.2:18000
```

| Field | Required | Description |
|-------|----------|-------------|
| `Host` | yes | Friendly name shown in menus |
| `HostName` | yes | IP address or hostname |
| `Port` | no | SSH port (default: 22) |
| `User` | no | SSH user (default: root) |
| `WorkDir` | no | Directory to `cd` into on login |
| `Proxy` | no | HTTP proxy for the server's outbound traffic |

`servers.conf` is in `.gitignore` and never committed.

## License

MIT
