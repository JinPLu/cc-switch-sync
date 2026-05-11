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
if not exist "!LOCAL_SETTINGS!" (
    echo   [ERROR] Local settings.json not found: !LOCAL_SETTINGS!
    pause
    exit /b 1
)

echo [1/2] Merging local env into remote settings.json ...
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
echo [2/2] Verifying ...
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST% "python3 -c \"import json,os; d=json.load(open(os.path.expanduser('~/.claude/settings.json'))); print('  ANTHROPIC_BASE_URL:', d.get('env',{}).get('ANTHROPIC_BASE_URL','NOT SET')); print('  ANTHROPIC_MODEL:', d.get('env',{}).get('ANTHROPIC_MODEL','NOT SET'))\""

echo.
echo =============================================
echo   Done! Config synced to %SVR_NAME%.
echo =============================================
pause
