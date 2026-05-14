@echo off
setlocal enabledelayedexpansion
title Sync Config
echo =============================================
echo   Sync CC Switch Provider Config to Server
echo =============================================
echo.

call "%~dp0_select-server.bat"
if errorlevel 2 exit /b 0
if "%SVR_HOST%"=="" (
    echo   [ERROR] No server selected.
    pause
    exit /b 1
)

echo.
echo   Target: %SVR_USER%@%SVR_HOST%:%SVR_PORT%  [%SVR_NAME%]
echo.

set "LOCAL_SETTINGS=%USERPROFILE%\.claude\settings.json"
set "LOCAL_CODEX_CONFIG=%USERPROFILE%\.codex\config.toml"
set "LOCAL_CODEX_AUTH=%USERPROFILE%\.codex\auth.json"

if not exist "!LOCAL_SETTINGS!" (
    echo   [ERROR] Local settings.json not found: !LOCAL_SETTINGS!
    pause
    exit /b 1
)

echo [1/3] Merging Claude env into remote settings.json ...
scp -P %SVR_PORT% "%LOCAL_SETTINGS%" %SVR_USER%@%SVR_HOST%:/tmp/cc-sync-local.json
if errorlevel 1 (
    echo   ERROR: SCP failed. Check SSH connection.
    pause
    exit /b 1
)
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "python3 -c \"import json,os; local=json.load(open('/tmp/cc-sync-local.json')); env=local.get('env',{}); path=os.path.expanduser('~/.claude/settings.json'); remote=json.load(open(path)) if os.path.exists(path) else {}; remote['env']=env; os.makedirs(os.path.dirname(path),exist_ok=True); open(path,'w').write(json.dumps(remote,indent=2)); os.remove('/tmp/cc-sync-local.json'); print('  env merged')\""
if errorlevel 1 (
    echo   ERROR: SSH merge failed.
    pause
    exit /b 1
)
echo   OK.

echo.
echo [2/3] Syncing Codex config ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "rm -f /tmp/cc-sync-codex-config.toml /tmp/cc-sync-codex-auth.json"
if exist "!LOCAL_CODEX_CONFIG!" (
    scp -P %SVR_PORT% "!LOCAL_CODEX_CONFIG!" %SVR_USER%@%SVR_HOST%:/tmp/cc-sync-codex-config.toml
    if errorlevel 1 (
        echo   ERROR: Codex config SCP failed.
        pause
        exit /b 1
    )
    if exist "!LOCAL_CODEX_AUTH!" (
        scp -P %SVR_PORT% "!LOCAL_CODEX_AUTH!" %SVR_USER%@%SVR_HOST%:/tmp/cc-sync-codex-auth.json
        if errorlevel 1 (
            echo   ERROR: Codex auth SCP failed.
            pause
            exit /b 1
        )
    ) else (
        echo   [WARN] Local Codex auth.json not found; syncing config.toml only.
    )
    ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "mkdir -p ~/.codex; cp /tmp/cc-sync-codex-config.toml ~/.codex/config.toml; chmod 600 ~/.codex/config.toml; rm -f /tmp/cc-sync-codex-config.toml; if [ -f /tmp/cc-sync-codex-auth.json ]; then cp /tmp/cc-sync-codex-auth.json ~/.codex/auth.json; chmod 600 ~/.codex/auth.json; rm -f /tmp/cc-sync-codex-auth.json; fi; echo '  codex config synced'"
    if errorlevel 1 (
        echo   ERROR: Codex remote install failed.
        pause
        exit /b 1
    )
) else (
    echo   [WARN] Local Codex config not found: !LOCAL_CODEX_CONFIG!
    echo   [WARN] Skipping Codex sync.
)
echo   OK.

echo.
echo [3/3] Verifying ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "echo '  Claude:'; python3 -c \"import json,os; d=json.load(open(os.path.expanduser('~/.claude/settings.json'))); print('    ANTHROPIC_BASE_URL:', d.get('env',{}).get('ANTHROPIC_BASE_URL','NOT SET')); print('    ANTHROPIC_MODEL:', d.get('env',{}).get('ANTHROPIC_MODEL','NOT SET'))\"; echo '  Codex:'; if [ -f ~/.codex/config.toml ]; then grep -E '^(model_provider|model|base_url) = ' ~/.codex/config.toml | sed 's/^/    /'; else echo '    config.toml: NOT SET'; fi; [ -f ~/.codex/auth.json ] && echo '    auth.json: present' || echo '    auth.json: missing'"

echo.
echo =============================================
echo   Done! Config synced to %SVR_NAME%.
echo =============================================
pause
