@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

set "CC_DB=%USERPROFILE%\.cc-switch\cc-switch.db"
set "SERVERS_FILE=%USERPROFILE%\.cc-switch-sync\servers.json"
set "WAIT=7"

echo.
echo =============================================
echo   CC Switch Sync - Push config to server
echo =============================================
echo.

if not exist "%CC_DB%" (
    echo   [ERROR] %CC_DB% not found.
    echo   Install CC Switch first: https://github.com/farion1231/cc-switch
    goto :end
)

if not exist "%SERVERS_FILE%" (
    echo   [ERROR] %SERVERS_FILE% not found.
    echo.
    echo   Create it with this format:
    echo   {
    echo     "servers": [
    echo       { "name": "my-server", "host": "10.0.0.1", "port": 22, "user": "root" }
    echo     ]
    echo   }
    echo.
    echo   Or run: notepad "%SERVERS_FILE%"
    goto :end
)

:: Parse servers
set "N=0"
for /f "delims=" %%a in ('powershell -NoProfile -Command "$j=Get-Content '%SERVERS_FILE%' -Raw|ConvertFrom-Json; $i=1; foreach($s in $j.servers){Write-Output ('{0}|{1}|{2}|{3}|{4}' -f $i,$s.name,$s.user,$s.host,$s.port);$i++}"') do (
    set /a N+=1
    set "S_!N!=%%a"
)

if "%N%"=="0" (
    echo   [ERROR] No servers in %SERVERS_FILE%
    goto :end
)

:: Handle --all
if "%~1"=="--all" (
    for /l %%i in (1,1,%N%) do call :sync %%i
    goto :end
)

:: Handle named argument
if not "%~1"=="" (
    for /l %%i in (1,1,%N%) do (
        for /f "tokens=2 delims=|" %%n in ("!S_%%i!") do (
            if "%%n"=="%~1" ( call :sync %%i & goto :end )
        )
    )
    echo   [ERROR] Server "%~1" not found.
    goto :end
)

:: Menu
echo   Servers:
for /l %%i in (1,1,%N%) do (
    for /f "tokens=1,2,3,4,5 delims=|" %%a in ("!S_%%i!") do echo   %%a. %%b  ^(%%c@%%d:%%e^)
)
echo.
set /p "C=  Select [1-%N%]: "
call :sync %C%
goto :end

:: ============================================================
:sync
for /f "tokens=2,3,4,5 delims=|" %%a in ("!S_%~1!") do (
    set "NAME=%%a" & set "USER=%%b" & set "HOST=%%c" & set "PORT=%%d"
)
echo.
echo   --- %NAME% (%USER%@%HOST%:%PORT%) ---
echo.

echo   [1/3] Copying DB...
scp -P %PORT% -o ConnectTimeout=10 "%CC_DB%" %USER%@%HOST%:~/.cc-switch/cc-switch.db >nul 2>&1
if errorlevel 1 ( echo   [FAILED] SCP error. Check: ssh -p %PORT% %USER%@%HOST% & goto :eof )
echo   OK
echo.

echo   [2/3] Applying config on server (wait %WAIT%s)...
ssh -p %PORT% -o ConnectTimeout=10 %USER%@%HOST% "pkill -f 'Xvfb :99' 2>/dev/null; Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 & sleep 1; DISPLAY=:99 cc-switch >/dev/null 2>&1 & sleep %WAIT%; pkill -f cc-switch 2>/dev/null; pkill -f 'Xvfb :99' 2>/dev/null; chmod 600 ~/.codex/auth.json ~/.claude/settings.json 2>/dev/null; echo OK"
echo.

echo   [3/3] Verifying...
ssh -p %PORT% -o ConnectTimeout=10 %USER%@%HOST% "echo '  -- Claude --'; grep -oP '\"ANTHROPIC_BASE_URL\": *\"[^\"]+\"' ~/.claude/settings.json 2>/dev/null || echo '  (none)'; echo '  -- Codex --'; grep -E 'base_url|model =' ~/.codex/config.toml 2>/dev/null | head -4 || echo '  (none)'"

echo.
echo   [DONE] %NAME% synced.
echo   claude: immediate / codex: restart terminal
echo.
goto :eof

:end
pause
