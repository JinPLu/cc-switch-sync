# cc-switch-sync

Windows batch scripts for managing remote Linux servers running [CC Switch](https://github.com/farion1231/cc-switch) — a provider proxy for Claude, Codex, and other AI coding tools.

## Scripts

Double-click any script to run it.

1. **`1. SSH Connect.bat`** — Pick a server from `servers.conf` and open an SSH session.
2. **`2. Sync Config.bat`** — Copy your local CC Switch provider database (`~/.cc-switch/cc-switch.db`) to the selected server, disable local routing, and restart CC Switch headlessly so it generates fresh `settings.json` / `config.toml` for Claude and Codex.
3. **`3. Add Server.bat`** — Interactively add a new server entry to `servers.conf` and optionally initialize it (install Xvfb + CC Switch, write proxy/workdir to `.bashrc`, sync DB).

`_select-server.bat` is a shared helper used by the scripts above — no need to run it directly.

## `servers.conf` format

SSH config style. Copy `servers.conf.example` to `servers.conf` and fill in your values.

```
Host lab-gpu
  HostName 10.x.x.x
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.x.x.x:18000
```

| Field | Required | Description |
|-------|----------|-------------|
| `Host` | yes | Friendly name shown in the selection menu |
| `HostName` | yes | IP address or hostname |
| `Port` | no | SSH port (default: 22) |
| `User` | no | SSH user (default: root) |
| `WorkDir` | no | Directory to `cd` into on login |
| `Proxy` | no | HTTP proxy for the server's outbound traffic |

`servers.conf` is in `.gitignore` — it never gets committed.

## One-time remote setup

`3. Add Server.bat` handles this automatically, but if you prefer to do it manually:

```bash
# Install Xvfb (required to run CC Switch headlessly)
apt-get install -y xvfb

# Download and install CC Switch
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc-switch.deb
apt install -y /tmp/cc-switch.deb
```

## Critical: disable local proxy routing in CC Switch

Before syncing, open CC Switch on **Windows**, go to **Settings**, and make sure:

```
enableLocalProxy = off
```

This prevents CC Switch from injecting a local proxy URL into the generated config. The server reads the config literally, so a `localhost:…` proxy address would fail on the remote machine.

The sync script also enforces this by running:
```sql
UPDATE proxy_config SET is_enabled = 0
```
on the copied database before restarting CC Switch.

## SSH key permissions (Windows)

If SSH refuses your key with a permissions error, fix it with `icacls`:

```cmd
icacls "C:\Users\YourName\.ssh\id_rsa" /inheritance:r /grant:r "%USERNAME%:R"
```

## License

MIT
