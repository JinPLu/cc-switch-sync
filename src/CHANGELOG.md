# Changelog

## Unreleased

- Cross-platform shell tool (native on macOS/Linux, Git Bash on Windows).
- One-line installers (`install.sh` / `install.ps1`). Windows installer drops a Desktop shortcut.
- Plugin system (`plugins/*.sh`) — `claude` and `codex` shipped, others pluggable.
- TUI: ASCII logo, colored status icons (Unicode + ASCII fallback), spinner during SSH/SCP.
- zh / en strings, auto-detected from `LANG`.
- Env-var overrides: `CCR_ASSUME_YES`, `CCR_LANGUAGE`, `CCR_THEME`, `CCR_ICON_SET`, `CCR_LOGIN_SHELL`, `NO_COLOR`.
