# CC Switch Remote Kit

Remote helper for CC Switch: sync local Claude Code / Codex provider config to a Linux server, open SSH, and download remote session history.

Chinese user guide lives at the release root as `使用说明.md`.

## Install

Download the latest release zip, extract it, then double-click:

- Windows: `安装 Windows.bat`
- macOS: `安装 macOS.command` (if Gatekeeper blocks it, right-click → Open)

The installer creates a `CC Switch Remote` Desktop shortcut and opens the first-time setup wizard.

Developer one-liners:

```sh
curl -fsSL https://raw.githubusercontent.com/farion1231/cc-switch-sync/main/src/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/farion1231/cc-switch-sync/main/src/install.ps1 | iex
```

## Usage

```sh
cc-remote setup          # first-time setup wizard
cc-remote                # interactive menu
cc-remote doctor         # check deps / plugins / servers
cc-remote add            # register a server
cc-remote test [name]    # test SSH
cc-remote sync [name]    # sync provider config
cc-remote connect [name] # SSH in
cc-remote history [name] # download session history
```

## Safety boundaries

- User config defaults to `~/.cc-remote/config.ini` and `~/.cc-remote/servers.conf`.
- Server init only writes to the `# >>> cc-switch-remote-kit >>>` block of remote `~/.bashrc`.
- Claude sync only merges the `env` object in `~/.claude/settings.json`; other keys untouched.
- Codex `auth.json` requires confirmation by default (`sync_codex_auth=confirm`).
- History saves to `~/.cc-remote/history-downloads/<server>/<timestamp>`; no local file is overwritten.

## Plugins

Plugin docs: `src/plugins/README.md`.
