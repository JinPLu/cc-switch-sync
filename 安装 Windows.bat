@echo off
setlocal
title Install CC Switch Remote
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0src\install.ps1"
if errorlevel 1 pause
