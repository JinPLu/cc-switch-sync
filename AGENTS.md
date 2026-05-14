# Repository Guidelines

## Project Structure & Module Organization

This repository contains Windows batch scripts for syncing CC Switch provider settings to remote Linux servers.

- `1. SSH Connect.bat`: user-facing entry point for selecting and connecting to a configured server.
- `2. Sync Config.bat`: user-facing script for copying local Claude and Codex settings to a server.
- `_select-server.bat`: shared server selection helper that parses `servers.conf`.
- `_add-server.bat`: interactive server registration and first-time remote initialization.
- `servers.conf.example`: committed template for private server entries.
- `README.md` and `README_EN.md`: Chinese and English usage docs.

Do not commit `servers.conf`, databases, local server registries, or editor metadata; these are covered by `.gitignore`.

## Build, Test, and Development Commands

There is no build system or package manager. Validate changes with Windows Command Prompt or PowerShell:

- `cmd /c "1. SSH Connect.bat"`: checks server selection and SSH connection flow.
- `cmd /c "2. Sync Config.bat"`: validates Claude env sync, Codex config/auth sync, SCP, SSH merge, and verification output.
- `cmd /c "_select-server.bat"`: tests parsing of `servers.conf` in isolation.

Use a throwaway or non-production host when testing initialization because `_add-server.bat` edits remote `~/.bashrc`.

## Coding Style & Naming Conventions

Batch files use `@echo off`, `setlocal enabledelayedexpansion`, uppercase environment variables, and clear status lines. Keep user-facing scripts numbered and descriptive; keep shared helpers prefixed with `_`. Preserve the SSH-config-like format in `servers.conf.example`:

```sshconfig
Host lab-gpu
  HostName 10.x.x.x
  Port 22
  User root
```

Prefer explicit error checks with `if errorlevel 1` after `ssh`, `scp`, and remote commands.

## Testing Guidelines

No automated test framework is present. Manually cover these paths before committing script changes: missing `servers.conf`, invalid menu input, adding a server, SSH failure, missing `%USERPROFILE%\.claude\settings.json`, missing `%USERPROFILE%\.codex\config.toml`, successful sync, and verification output. If parsing changes, test multiple `Host` blocks with omitted optional fields.

## Commit & Pull Request Guidelines

Recent history uses short imperative commit messages, for example `Fix friction: ...` and `Simplify README: ...`. Follow that pattern: start with a verb, name the affected area, and keep the subject concise.

Pull requests should include the user workflow tested, any remote side effects, and screenshots or copied console output for interactive script changes. Mention changes to config format or required remote dependencies.

## Agent-Specific Instructions

Research the current scripts and docs before proposing changes. The execution copy is on `10.40.1.181:/media/datasets/OminiEWM_Data/tmp/ljp/OoVMetric`; keep local and server repositories synchronized with Git when work must run there.
