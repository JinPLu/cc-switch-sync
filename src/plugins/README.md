# Plugin API

Drop a file at `plugins/<name>.sh`, add `<name>` to `enable_plugins=` in `~/.cc-remote/config.ini`, done.

## Contract

```sh
#!/usr/bin/env bash
PLUGIN_NAME="cursor"
PLUGIN_TITLE="Cursor"

cursor_doctor() {                # required: print local-state checks
    [ -f "$HOME/.cursor/config.json" ] && ccr_status OK "Cursor config found." \
        || { ccr_status WARN "Cursor config missing."; return 1; }
}

cursor_sync() {                  # required: --summary for plan line, else do work
    [ "${1:-}" = "--summary" ] && { echo "Cursor: upload ~/.cursor/config.json"; return; }
    ccr_spin "Uploading Cursor config" ccr_upload "$HOME/.cursor/config.json" "/tmp/ccrk-cursor.json"
    ccr_remote "mkdir -p ~/.cursor && mv /tmp/ccrk-cursor.json ~/.cursor/config.json"
}

cursor_history_paths() {         # optional: remote paths to tar (relative to ~)
    printf '%s\n' '.cursor/sessions'
}
```

Function names are `<PLUGIN_NAME>_doctor` / `_sync` / `_history_paths`.

## Helpers (always available)

- `ccr_status OK|ERR|WARN|INFO|SKIP "msg"` — colored status line
- `ccr_spin "label" cmd args...` — run under spinner
- `ccr_upload <local> <remote>` / `ccr_download <remote> <local>` — scp wrappers
- `ccr_remote "<shell cmd>"` — run on remote host
- `ccr_confirm "prompt" 0|1` — y/N or Y/n
- `$CCR_SRV_NAME / HOST / PORT / USER / WORKDIR / PROXY / IDENTITY` — current target

Use `/tmp/ccrk-*` for remote temp files and clean up. Never overwrite remote secrets without confirmation.
