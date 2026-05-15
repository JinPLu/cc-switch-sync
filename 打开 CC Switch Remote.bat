@echo off
setlocal
title CC Switch Remote

set "APP_ROOT=%~dp0"
set "APP_ROOT=%APP_ROOT:~0,-1%"
set "APP_ROOT_UNIX=%APP_ROOT:\=/%"

set "GIT_BASH="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "GIT_BASH=%ProgramFiles%\Git\bin\bash.exe"
if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "GIT_BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "GIT_BASH=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"

if "%GIT_BASH%"=="" (
    echo [ERROR] Git Bash not found.
    echo.
    echo Please install Git for Windows first:
    echo   winget install --id Git.Git -e
    echo   https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

if not exist "%APP_ROOT%\src\bin\cc-remote" (
    echo [ERROR] src\bin\cc-remote not found.
    echo.
    echo Please run "安装 Windows.bat" from the extracted package first.
    echo.
    pause
    exit /b 1
)

if "%CCR_LOGIN_SHELL%"=="1" (
    "%GIT_BASH%" --login -i -c "exec '%APP_ROOT_UNIX%/src/bin/cc-remote' %*"
) else (
    "%GIT_BASH%" -c "exec '%APP_ROOT_UNIX%/src/bin/cc-remote' %*"
)
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [ERROR] CC Switch Remote exited with code %RC%.
    pause
)
exit /b %RC%
