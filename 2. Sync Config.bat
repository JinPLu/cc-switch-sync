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

set "LOCAL_DB=%USERPROFILE%\.cc-switch\cc-switch.db"
if not exist "!LOCAL_DB!" (
    echo   [ERROR] CC Switch DB not found: !LOCAL_DB!
    echo   Please install CC Switch and configure a Provider first.
    pause
    exit /b 1
)

echo [1/3] Copying CC Switch DB ...
scp -P %SVR_PORT% "%LOCAL_DB%" %SVR_USER%@%SVR_HOST%:~/.cc-switch/cc-switch.db
if errorlevel 1 (
    echo   ERROR: SCP failed. Check SSH connection.
    pause
    exit /b 1
)
echo   OK.

echo.
echo [2/3] Applying config (7s) ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "python3 -c \"import sqlite3;c=sqlite3.connect('/root/.cc-switch/cc-switch.db');c.execute('UPDATE proxy_config SET is_enabled=0');c.commit();c.close();print('  Local Routing disabled')\" 2>/dev/null; pkill cc-switch 2>/dev/null; sleep 1; xvfb-run --auto-servernum cc-switch >/tmp/cc-switch-sync.log 2>&1 & sleep 7; pkill cc-switch 2>/dev/null"
echo   OK.

echo.
echo [3/3] Verifying ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "echo '  Claude:' && grep ANTHROPIC_BASE_URL ~/.claude/settings.json 2>/dev/null | head -1 || echo '    (not set)'; echo '  Codex:' && grep base_url ~/.codex/config.toml 2>/dev/null | head -1 || echo '    (not set)'"

echo.
echo =============================================
echo   Done! Config synced to %SVR_NAME%.
echo =============================================
pause
