@echo off
setlocal enabledelayedexpansion
title Download History
echo =============================================
echo   Download Claude/Codex History from Server
echo =============================================
echo.

call "%~dp0_select-server.bat"
if errorlevel 2 exit /b 0
if "%SVR_HOST%"=="" (
    echo   [ERROR] No server selected.
    pause
    exit /b 1
)

for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%t"

set "DOWNLOAD_ROOT=%USERPROFILE%\.cc-switch-sync\history-downloads"
set "DEST=%DOWNLOAD_ROOT%\%SVR_NAME%\!TS!"
set "LOCAL_TAR=!DEST!\history.tar.gz"
set "REMOTE_TAR=/tmp/cc-switch-history-!TS!.tar.gz"

echo.
echo   Target: %SVR_USER%@%SVR_HOST%:%SVR_PORT%  [%SVR_NAME%]
echo   Local:  !DEST!
echo.

mkdir "!DEST!" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Failed to create local download folder.
    pause
    exit /b 1
)

echo [1/4] Checking remote history ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "echo '  Codex session files:'; find ~/.codex/sessions ~/.codex/archived_sessions -type f -name '*.jsonl' 2>/dev/null | wc -l; echo '  Claude project files:'; find ~/.claude/projects ~/.claude/sessions -type f -name '*.jsonl' 2>/dev/null | wc -l"
if errorlevel 1 (
    echo   ERROR: SSH failed. Check connection.
    pause
    exit /b 1
)

echo.
echo [2/4] Creating remote archive ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "rm -f '!REMOTE_TAR!'; cd ~; tar --ignore-failed-read -czf '!REMOTE_TAR!' .codex/sessions .codex/archived_sessions .codex/history.jsonl .codex/session_index.jsonl .codex/state_5.sqlite .codex/state_5.sqlite-wal .codex/state_5.sqlite-shm .claude/projects .claude/sessions .claude/history.jsonl .claude.json 2>/tmp/cc-switch-history-tar.err || true; if [ -f '!REMOTE_TAR!' ]; then ls -lh '!REMOTE_TAR!'; else cat /tmp/cc-switch-history-tar.err; exit 1; fi"
if errorlevel 1 (
    echo   ERROR: Remote archive failed.
    pause
    exit /b 1
)

echo.
echo [3/4] Downloading archive ...
scp -P %SVR_PORT% %SVR_USER%@%SVR_HOST%:!REMOTE_TAR! "!LOCAL_TAR!"
if errorlevel 1 (
    echo   ERROR: SCP failed.
    pause
    exit /b 1
)
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "rm -f '!REMOTE_TAR!'" >nul 2>&1

echo.
echo [4/4] Extracting archive ...
tar -xzf "!LOCAL_TAR!" -C "!DEST!"
if errorlevel 1 (
    echo   ERROR: Extract failed. Archive kept at: !LOCAL_TAR!
    pause
    exit /b 1
)

echo.
echo   Download complete.
echo   Archive folder: !DEST!
echo.
echo   This script did not overwrite local auth/config/settings/sqlite files.
echo.
set /p "IMPORT=  Import JSONL session files into local active folders for CC Switch browsing? [y/N]: "
if /i not "!IMPORT!"=="y" goto done

echo.
echo   Importing session JSONL files only ...

if exist "!DEST!\.codex\sessions" (
    mkdir "%USERPROFILE%\.codex\sessions" >nul 2>&1
    robocopy "!DEST!\.codex\sessions" "%USERPROFILE%\.codex\sessions" /E /XC /XN /XO
    if errorlevel 8 (
        echo   ERROR: Failed to import Codex sessions.
        pause
        exit /b 1
    )
)

if exist "!DEST!\.codex\archived_sessions" (
    mkdir "%USERPROFILE%\.codex\archived_sessions" >nul 2>&1
    robocopy "!DEST!\.codex\archived_sessions" "%USERPROFILE%\.codex\archived_sessions" /E /XC /XN /XO
    if errorlevel 8 (
        echo   ERROR: Failed to import Codex archived sessions.
        pause
        exit /b 1
    )
)

if exist "!DEST!\.claude\projects" (
    mkdir "%USERPROFILE%\.claude\projects" >nul 2>&1
    robocopy "!DEST!\.claude\projects" "%USERPROFILE%\.claude\projects" /E /XC /XN /XO
    if errorlevel 8 (
        echo   ERROR: Failed to import Claude project sessions.
        pause
        exit /b 1
    )
)

if exist "!DEST!\.claude\sessions" (
    mkdir "%USERPROFILE%\.claude\sessions" >nul 2>&1
    robocopy "!DEST!\.claude\sessions" "%USERPROFILE%\.claude\sessions" /E /XC /XN /XO
    if errorlevel 8 (
        echo   ERROR: Failed to import Claude sessions.
        pause
        exit /b 1
    )
)

echo.
echo   Import complete. CC Switch can rescan local session folders.
echo   Codex/Claude official resume indexes were not modified.

:done
echo.
echo =============================================
echo   Done! History downloaded from %SVR_NAME%.
echo =============================================
pause
