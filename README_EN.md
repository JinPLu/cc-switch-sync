# cc-switch-sync

Companion scripts for [CC Switch](https://github.com/farion1231/cc-switch) — double-click to push your local AI provider config to remote Linux servers.

[中文](README.md)

## Quick Start

### Step 1: One-time setup

**Local (Windows)**

1. Install [CC Switch](https://github.com/farion1231/cc-switch/releases) and configure a Provider (API Key + Base URL)
2. Settings → disable `enableLocalProxy` (otherwise remote servers receive a `localhost` address that won't work)

**Remote server** (`3. Add Server.bat` can do this automatically)

```bash
apt-get install -y xvfb
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc.deb
apt install -y /tmp/cc.deb
```

### Step 2: Clone and fill in your server list

```bash
git clone https://github.com/JinPLu/cc-switch-sync.git
```

Copy `servers.conf.example` to `servers.conf` and fill in your server details.

## Usage

Double-click a script to run it:

| Script | What it does |
|--------|--------------|
| `1. SSH Connect.bat` | SSH into a server |
| `2. Sync Config.bat` | Push current Provider config to a server |
| `3. Add Server.bat` | Add a new server (with optional auto-init) |

## `servers.conf` format

```
Host my-server
  HostName 10.0.0.1
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.0.0.2:18000
```

`WorkDir` and `Proxy` are optional. `servers.conf` is in `.gitignore` and never committed.

## License

MIT
