@echo off
REM =============================================
REM  _select-server.bat
REM  解析 servers.conf（SSH config 风格），展示列表，
REM  用户选择后设置 SVR_* 环境变量供调用方使用。
REM =============================================
setlocal enabledelayedexpansion

set "CONF=%~dp0servers.conf"

if not exist "!CONF!" (
    echo   [ERROR] servers.conf not found: !CONF!
    endlocal
    exit /b 1
)

set /a COUNT=0

REM Parse config file
for /f "usebackq tokens=1,* delims= " %%a in ("!CONF!") do (
    if /i "%%a"=="Host" (
        set /a COUNT+=1
        set "S_!COUNT!_NAME=%%b"
        set "S_!COUNT!_PORT=22"
        set "S_!COUNT!_PROXY="
        set "S_!COUNT!_WORKDIR="
    )
    if /i "%%a"=="HostName" set "S_!COUNT!_HOST=%%b"
    if /i "%%a"=="Port" set "S_!COUNT!_PORT=%%b"
    if /i "%%a"=="User" set "S_!COUNT!_USER=%%b"
    if /i "%%a"=="WorkDir" set "S_!COUNT!_WORKDIR=%%b"
    if /i "%%a"=="Proxy" set "S_!COUNT!_PROXY=%%b"
)

if !COUNT!==0 (
    echo   [ERROR] No servers defined in servers.conf
    endlocal
    exit /b 1
)

echo   Available servers:
echo   ------------------
for /l %%i in (1,1,!COUNT!) do (
    echo   %%i. !S_%%i_NAME!  ^(!S_%%i_USER!@!S_%%i_HOST!:!S_%%i_PORT!^)
)
set /a ADDNUM=!COUNT!+1
echo   !ADDNUM!. [+ Add new server]

echo.
set /p CHOICE="  Select [1-!ADDNUM!]: "

REM Check if user chose "Add new server"
if "!CHOICE!"=="!ADDNUM!" (
    endlocal
    call "%~dp0_add-server.bat"
    exit /b 2
)

REM Validate
echo !CHOICE!| findstr /r "^[0-9][0-9]*$" >nul 2>&1
if errorlevel 1 (
    echo   [ERROR] Invalid selection.
    endlocal
    exit /b 1
)
if !CHOICE! LSS 1 (
    echo   [ERROR] Invalid selection.
    endlocal
    exit /b 1
)
if !CHOICE! GTR !COUNT! (
    echo   [ERROR] Invalid selection.
    endlocal
    exit /b 1
)

set "_NAME=!S_%CHOICE%_NAME!"
set "_HOST=!S_%CHOICE%_HOST!"
set "_PORT=!S_%CHOICE%_PORT!"
set "_USER=!S_%CHOICE%_USER!"
set "_WORKDIR=!S_%CHOICE%_WORKDIR!"
set "_PROXY=!S_%CHOICE%_PROXY!"

endlocal & set "SVR_NAME=%_NAME%" & set "SVR_HOST=%_HOST%" & set "SVR_PORT=%_PORT%" & set "SVR_USER=%_USER%" & set "SVR_WORKDIR=%_WORKDIR%" & set "SVR_PROXY=%_PROXY%"
