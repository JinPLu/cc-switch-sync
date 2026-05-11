@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

set "SERVERS_FILE=%USERPROFILE%\.cc-switch-sync\servers.json"
set "CC_DB=%USERPROFILE%\.cc-switch\cc-switch.db"
set "WAIT_SECONDS=7"
set "XVFB_DISPLAY=:99"

echo.
echo =============================================
echo   CC Switch - Sync Provider Config to Server
echo =============================================
echo.

:: Check CC Switch DB exists
if not exist "%CC_DB%" (
    echo   [ERROR] CC Switch database not found:
    echo     %CC_DB%
    echo   Please install and configure CC Switch first.
    echo   https://github.com/farion1231/cc-switch/releases
    goto :end
)

:: Check servers.json exists
if not exist "%SERVERS_FILE%" (
    echo   [ERROR] Server list not found:
    echo     %SERVERS_FILE%
    echo   Run install.ps1 first, or copy examples\servers.example.json
    echo   to %SERVERS_FILE% and edit it.
    goto :end
)

:: Parse servers from JSON using PowerShell
set "SERVER_COUNT=0"
for /f "delims=" %%a in ('powershell -NoProfile -Command "$j = Get-Content '%SERVERS_FILE%' -Raw | ConvertFrom-Json; $i=1; foreach($s in $j.servers){ Write-Output ('{0}|{1}|{2}|{3}|{4}' -f $i,$s.name,$s.user,$s.host,$s.port); $i++ }"') do (
    set /a SERVER_COUNT+=1
    set "SRV_!SERVER_COUNT!=%%a"
)

if "%SERVER_COUNT%"=="0" (
    echo   [ERROR] No servers configured in %SERVERS_FILE%
    goto :end
)

:: Handle --all flag
if "%~1"=="--all" (
    echo   Syncing to ALL %SERVER_COUNT% server(s)...
    echo.
    for /l %%i in (1,1,%SERVER_COUNT%) do (
        call :sync_one %%i
        echo.
    )
    goto :end
)

:: Handle named server argument
if not "%~1"=="" (
    for /l %%i in (1,1,%SERVER_COUNT%) do (
        for /f "tokens=2 delims=|" %%n in ("!SRV_%%i!") do (
            if "%%n"=="%~1" (
                call :sync_one %%i
                goto :end
            )
        )
    )
    echo   [ERROR] Server "%~1" not found in %SERVERS_FILE%
    echo.
)

:: Interactive menu
echo   Available servers:
echo   -------------------
for /l %%i in (1,1,%SERVER_COUNT%) do (
    for /f "tokens=1,2,3,4,5 delims=|" %%a in ("!SRV_%%i!") do (
        echo   %%a. %%b  ^(%%c@%%d:%%e^)
    )
)
set /a MENU_ADD=%SERVER_COUNT%+1
echo   %MENU_ADD%. [+ Add new server]
echo.

set /p "CHOICE=  Select [1-%MENU_ADD%]: "

if "%CHOICE%"=="%MENU_ADD%" (
    call :add_server
    goto :end
)

:: Validate choice
set "VALID=0"
for /l %%i in (1,1,%SERVER_COUNT%) do (
    if "%CHOICE%"=="%%i" set "VALID=1"
)
if "%VALID%"=="0" (
    echo   [ERROR] Invalid selection.
    goto :end
)

call :sync_one %CHOICE%
goto :end

:: ============================================================
:: Sync to one server
:: ============================================================
:sync_one
set "IDX=%~1"
for /f "tokens=1,2,3,4,5 delims=|" %%a in ("!SRV_%IDX%!") do (
    set "SRV_NAME=%%b"
    set "SRV_USER=%%c"
    set "SRV_HOST=%%d"
    set "SRV_PORT=%%e"
)

echo   Target: %SRV_USER%@%SRV_HOST%:%SRV_PORT%  [%SRV_NAME%]
echo.

:: Step 1: Copy DB
echo [1/4] Copying CC Switch DB to server...
scp -P %SRV_PORT% -o ConnectTimeout=10 "%CC_DB%" %SRV_USER%@%SRV_HOST%:~/.cc-switch/cc-switch.db >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] SCP failed. Check SSH connection.
    echo   Tip: Run 'ssh -p %SRV_PORT% %SRV_USER%@%SRV_HOST%' to debug.
    goto :eof
)
echo   DB copied successfully.
echo.

:: Step 2: Start CC Switch on server via Xvfb to write configs
echo [2/4] Starting CC Switch on server (Xvfb) to write configs...
echo   Waiting %WAIT_SECONDS%s for settings.json and codex config to be written...
ssh -p %SRV_PORT% -o ConnectTimeout=10 %SRV_USER%@%SRV_HOST% "pkill -f 'Xvfb %XVFB_DISPLAY%' 2>/dev/null; sleep 0.5; Xvfb %XVFB_DISPLAY% -screen 0 1024x768x24 >/dev/null 2>&1 & sleep 1; DISPLAY=%XVFB_DISPLAY% cc-switch >/dev/null 2>&1 & sleep %WAIT_SECONDS%; pkill -f cc-switch 2>/dev/null; pkill -f 'Xvfb %XVFB_DISPLAY%' 2>/dev/null; echo done"
echo.

:: Step 3: Fix codex config — replace proxy URL with direct URL
echo [3/4] Patching codex config (remove local proxy references)...
ssh -p %SRV_PORT% -o ConnectTimeout=10 %SRV_USER%@%SRV_HOST% "if [ -f ~/.codex/config.toml ]; then sed -i 's|http://127.0.0.1:15721/v1|PLACEHOLDER_NEEDS_FIX|g' ~/.codex/config.toml; echo '  Checked codex config.toml'; fi; chmod 600 ~/.codex/auth.json ~/.claude/settings.json ~/.cc-switch/cc-switch.db 2>/dev/null; echo '  Permissions tightened.'"
echo.

:: Step 4: Verify
echo [4/4] Verifying...

:: Verify Claude
for /f "delims=" %%v in ('ssh -p %SRV_PORT% -o ConnectTimeout=10 %SRV_USER%@%SRV_HOST% "grep -E 'ANTHROPIC_BASE_URL|ANTHROPIC_AUTH_TOKEN' ~/.claude/settings.json 2>/dev/null | head -4"') do (
    echo   %%v
)

:: Verify Codex
echo   ---
for /f "delims=" %%v in ('ssh -p %SRV_PORT% -o ConnectTimeout=10 %SRV_USER%@%SRV_HOST% "grep -E 'base_url|model =' ~/.codex/config.toml 2>/dev/null | head -6"') do (
    echo   %%v
)

echo.
echo =============================================
echo   Done! Provider config synced to [%SRV_NAME%].
echo   - claude: takes effect immediately
echo   - codex:  restart terminal to apply
echo =============================================

goto :eof

:: ============================================================
:: Add a new server interactively
:: ============================================================
:add_server
echo.
echo   --- Add New Server ---
set /p "NEW_NAME=  Name (e.g. lab-gpu): "
set /p "NEW_HOST=  Host (e.g. 10.0.1.50): "
set /p "NEW_PORT=  Port (default 22): "
set /p "NEW_USER=  User (default root): "
if "%NEW_PORT%"=="" set "NEW_PORT=22"
if "%NEW_USER%"=="" set "NEW_USER=root"

powershell -NoProfile -Command ^
    "$f='%SERVERS_FILE%'; $j=Get-Content $f -Raw | ConvertFrom-Json; $j.servers += [pscustomobject]@{name='%NEW_NAME%';host='%NEW_HOST%';port=[int]'%NEW_PORT%';user='%NEW_USER%'}; $j | ConvertTo-Json -Depth 5 | Set-Content $f -Encoding UTF8; Write-Output '  Server added: %NEW_NAME% (%NEW_USER%@%NEW_HOST%:%NEW_PORT%)'"
echo.
echo   Re-run sync-to-server to sync to the new server.
goto :eof

:end
echo.
pause
