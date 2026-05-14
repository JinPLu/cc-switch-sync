# cc-switch-sync

Companion scripts for [CC Switch](https://github.com/farion1231/cc-switch) — double-click to push your local Claude and Codex AI provider config to remote Linux servers, or download remote chat history back to your local machine.

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
| `3. Download History.bat` | Download Claude/Codex chat history from a server into a local archive, with an optional JSONL-only import for CC Switch browsing |

Codex sync directly overwrites remote `~/.codex/config.toml`. If local `auth.json` exists, it directly overwrites remote `~/.codex/auth.json` too.

History downloads are saved to `%USERPROFILE%\.cc-switch-sync\history-downloads\<server>\<timestamp>` by default. The script does not overwrite local `auth.json`, `config.toml`, `settings.json`, or sqlite indexes. The optional import copies only Claude/Codex JSONL session files so CC Switch can scan them; official Codex/Claude `resume` indexes are not modified.

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
