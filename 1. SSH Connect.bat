@echo off
setlocal enabledelayedexpansion
title SSH Connect
echo =============================================
echo   SSH Connect
echo =============================================
echo.

:select
call "%~dp0_select-server.bat"
if errorlevel 2 goto select
if "%SVR_HOST%"=="" (
    echo   [ERROR] No server selected.
    pause
    exit /b 1
)

echo.
echo   ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST%
echo.
ssh -p %SVR_PORT% %SVR_USER%@%SVR_HOST%
pause
