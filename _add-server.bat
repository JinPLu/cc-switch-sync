@echo off
setlocal enabledelayedexpansion
title Add & Initialize Server
echo =============================================
echo   Add New Server + Initialize Environment
echo =============================================
echo.

set "CONF=%~dp0servers.conf"
set "LOCAL_DB=%USERPROFILE%\.cc-switch\cc-switch.db"

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
set /p "INIT=  Initialize this server now? (install CC Switch etc.) [Y/n]: "
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
echo [2/4] Installing Xvfb + CC Switch ...
ssh -p !PORT! !USER!@!HOST! "apt-get update -qq && apt-get install -y xvfb 2>&1 | tail -2 && echo '  Xvfb ready'"

if not "!PROXY!"=="" (
    ssh -p !PORT! !USER!@!HOST! "if [ -f /usr/bin/cc-switch ]; then echo '  CC Switch already installed'; else https_proxy=!PROXY! wget -q https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc-switch.deb && apt install -y /tmp/cc-switch.deb 2>&1 | tail -2 && echo '  CC Switch installed' || echo '  WARNING: install failed'; fi"
) else (
    ssh -p !PORT! !USER!@!HOST! "if [ -f /usr/bin/cc-switch ]; then echo '  CC Switch already installed'; else wget -q https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc-switch.deb && apt install -y /tmp/cc-switch.deb 2>&1 | tail -2 && echo '  CC Switch installed' || echo '  WARNING: install failed'; fi"
)

echo.
echo [3/4] Syncing CC Switch DB ...
ssh -p !PORT! !USER!@!HOST! "mkdir -p ~/.cc-switch"
if not exist "!LOCAL_DB!" (
    echo   [ERROR] CC Switch DB not found: !LOCAL_DB!
    echo   Please open CC Switch GUI and configure a Provider first.
    pause
    exit /b 1
)
scp -P !PORT! "!LOCAL_DB!" !USER!@!HOST!:~/.cc-switch/cc-switch.db
if errorlevel 1 (
    echo   ERROR: SCP failed.
    pause
    exit /b 1
)
echo   DB copied. Generating settings.json (7s) ...
ssh -p !PORT! !USER!@!HOST! "python3 -c \"import os,sqlite3;c=sqlite3.connect(os.path.expanduser('~/.cc-switch/cc-switch.db'));c.execute('UPDATE proxy_config SET is_enabled=0');c.commit();c.close();print('  Local Routing disabled')\" 2>/dev/null; pkill cc-switch 2>/dev/null; sleep 1; xvfb-run --auto-servernum cc-switch >/tmp/cc-switch-init.log 2>&1 & sleep 7; pkill cc-switch 2>/dev/null"
echo   OK.

echo.
echo [4/4] Verifying ...
ssh -p !PORT! !USER!@!HOST! "echo '  Claude:' && grep ANTHROPIC_BASE_URL ~/.claude/settings.json 2>/dev/null | head -1 || echo '    (not set)'; echo '  Codex:' && grep base_url ~/.codex/config.toml 2>/dev/null | head -1 || echo '    (not set)'; echo '  Proxy:' && grep http_proxy ~/.bashrc | head -1 || echo '    (none)'"

echo.
echo =============================================
echo   Server "!NAME!" is ready!
echo   Use "1. SSH Connect.bat" to connect, then: claude
echo =============================================
pause
