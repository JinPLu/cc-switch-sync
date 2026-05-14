@echo off
setlocal enabledelayedexpansion
title Add & Initialize Server
echo =============================================
echo   Add New Server + Initialize Environment
echo =============================================
echo.

set "CONF=%~dp0servers.conf"

echo   Current servers:
echo   ------------------
if exist "!CONF!" (
    for /f "usebackq tokens=1,* delims= " %%a in ("!CONF!") do (
        if /i "%%a"=="Host" echo   - %%b
    )
) else (
    echo   (none yet)
)
echo.
echo   --- Step 1: Server Info ---
echo.

set /p "NAME=  Name (e.g. lab-gpu): "
if "!NAME!"=="" (
    echo   [Cancelled]
    pause
    exit /b 0
)

set /p "HOST=  HostName / IP: "
if "!HOST!"=="" (
    echo   [ERROR] HostName is required.
    pause
    exit /b 1
)

set /p "PORT=  Port [22]: "
if "!PORT!"=="" set "PORT=22"

set /p "USER=  User [root]: "
if "!USER!"=="" set "USER=root"

set /p "WORKDIR=  WorkDir [~]: "
if "!WORKDIR!"=="" set "WORKDIR=~"

set /p "PROXY=  Proxy (empty if none): "

echo.
echo   Preview:
echo   ------------------
echo   Host !NAME!
echo     HostName !HOST!
echo     Port !PORT!
echo     User !USER!
echo     WorkDir !WORKDIR!
if not "!PROXY!"=="" echo     Proxy !PROXY!
echo   ------------------
echo.
set /p "CONFIRM=  Add to servers.conf? [Y/n]: "
if /i "!CONFIRM!"=="n" (
    echo   [Cancelled]
    pause
    exit /b 0
)

REM Write to servers.conf
(
    echo.
    echo Host !NAME!
    echo   HostName !HOST!
    echo   Port !PORT!
    echo   User !USER!
    echo   WorkDir !WORKDIR!
    if not "!PROXY!"=="" echo   Proxy !PROXY!
) >> "!CONF!"
echo   Added to servers.conf.

echo.
set /p "INIT=  Initialize this server now? [Y/n]: "
if /i "!INIT!"=="n" (
    echo.
    echo   Done. Run "2. Sync Config.bat" later to push provider config.
    pause
    exit /b 0
)

REM === Initialize Server ===
echo.
echo   --- Step 2: Initialize Server ---
echo.

echo [1/4] Writing .bashrc (proxy + workdir) ...
ssh -p !PORT! !USER!@!HOST! "sed -i '/^# === Proxy/,/^$/d' ~/.bashrc; sed -i '/^# === Default working/,/^$/d' ~/.bashrc; sed -i '/^export http_proxy/d' ~/.bashrc; sed -i '/^export https_proxy/d' ~/.bashrc; sed -i '/^cd \//d' ~/.bashrc"

if not "!PROXY!"=="" (
    ssh -p !PORT! !USER!@!HOST! "printf '\n# === Proxy Configuration ===\nexport http_proxy=!PROXY!\nexport https_proxy=!PROXY!\n\n# === Default working directory ===\ncd !WORKDIR!\n' >> ~/.bashrc"
) else (
    ssh -p !PORT! !USER!@!HOST! "printf '\n# === Default working directory ===\ncd !WORKDIR!\n' >> ~/.bashrc"
)
echo   OK.

echo.
echo [2/4] Syncing Claude settings.json ...
set "LOCAL_SETTINGS=%USERPROFILE%\.claude\settings.json"
if not exist "!LOCAL_SETTINGS!" (
    echo   [ERROR] Local settings.json not found: !LOCAL_SETTINGS!
    pause
    exit /b 1
)
scp -P !PORT! "!LOCAL_SETTINGS!" !USER!@!HOST!:/tmp/cc-sync-local.json
if errorlevel 1 (
    echo   ERROR: SCP failed.
    pause
    exit /b 1
)
ssh -p !PORT! !USER!@!HOST! "python3 -c \"import json,os; local=json.load(open('/tmp/cc-sync-local.json')); env=local.get('env',{}); path=os.path.expanduser('~/.claude/settings.json'); remote=json.load(open(path)) if os.path.exists(path) else {}; remote['env']=env; os.makedirs(os.path.dirname(path),exist_ok=True); open(path,'w').write(json.dumps(remote,indent=2)); os.remove('/tmp/cc-sync-local.json'); print('  env merged')\""
if errorlevel 1 (
    echo   ERROR: SSH merge failed.
    pause
    exit /b 1
)
echo   OK.

echo.
echo [3/4] Syncing Codex config ...
set "LOCAL_CODEX_CONFIG=%USERPROFILE%\.codex\config.toml"
set "LOCAL_CODEX_AUTH=%USERPROFILE%\.codex\auth.json"
ssh -p !PORT! !USER!@!HOST! "rm -f /tmp/cc-sync-codex-config.toml /tmp/cc-sync-codex-auth.json"
if exist "!LOCAL_CODEX_CONFIG!" (
    scp -P !PORT! "!LOCAL_CODEX_CONFIG!" !USER!@!HOST!:/tmp/cc-sync-codex-config.toml
    if errorlevel 1 (
        echo   ERROR: Codex config SCP failed.
        pause
        exit /b 1
    )
    if exist "!LOCAL_CODEX_AUTH!" (
        scp -P !PORT! "!LOCAL_CODEX_AUTH!" !USER!@!HOST!:/tmp/cc-sync-codex-auth.json
        if errorlevel 1 (
            echo   ERROR: Codex auth SCP failed.
            pause
            exit /b 1
        )
    ) else (
        echo   [WARN] Local Codex auth.json not found; syncing config.toml only.
    )
    ssh -p !PORT! !USER!@!HOST! "mkdir -p ~/.codex; cp /tmp/cc-sync-codex-config.toml ~/.codex/config.toml; chmod 600 ~/.codex/config.toml; rm -f /tmp/cc-sync-codex-config.toml; if [ -f /tmp/cc-sync-codex-auth.json ]; then cp /tmp/cc-sync-codex-auth.json ~/.codex/auth.json; chmod 600 ~/.codex/auth.json; rm -f /tmp/cc-sync-codex-auth.json; fi; echo '  codex config synced'"
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
echo [4/4] Verifying ...
ssh -p !PORT! !USER!@!HOST! "echo '  Claude:' && python3 -c \"import json,os; d=json.load(open(os.path.expanduser('~/.claude/settings.json'))); print('    ANTHROPIC_BASE_URL:', d.get('env',{}).get('ANTHROPIC_BASE_URL','NOT SET')); print('    ANTHROPIC_MODEL:', d.get('env',{}).get('ANTHROPIC_MODEL','NOT SET'))\" 2>/dev/null || echo '    (not set)'; echo '  Codex:'; if [ -f ~/.codex/config.toml ]; then grep -E '^(model_provider|model|base_url) = ' ~/.codex/config.toml | sed 's/^/    /'; else echo '    config.toml: NOT SET'; fi; [ -f ~/.codex/auth.json ] && echo '    auth.json: present' || echo '    auth.json: missing'; echo '  Proxy:' && grep http_proxy ~/.bashrc | head -1 || echo '    (none)'"

echo.
echo =============================================
echo   Server "!NAME!" is ready!
echo   Use "1. SSH Connect.bat" to connect, then: claude
echo =============================================
pause
