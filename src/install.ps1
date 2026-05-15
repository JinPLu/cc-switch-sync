# install.ps1 — one-line Windows installer.
#   irm https://raw.githubusercontent.com/farion1231/cc-switch-sync/main/src/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$Repo       = if ($env:CCR_REPO)        { $env:CCR_REPO }        else { 'https://github.com/farion1231/cc-switch-sync.git' }
$Branch     = if ($env:CCR_BRANCH)      { $env:CCR_BRANCH }      else { 'main' }
$InstallDir = if ($env:CCR_INSTALL_DIR) { $env:CCR_INSTALL_DIR } else { Join-Path $env:USERPROFILE '.cc-remote' }

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$LocalSource = if (Test-Path (Join-Path $ScriptDir 'bin\cc-remote')) { Split-Path -Parent $ScriptDir } else { $null }

function Say($msg, $color = 'Cyan') { Write-Host $msg -ForegroundColor $color }

Say "`nCC Switch Remote Kit — installer"

# Git Bash check.
$gitBash = @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $gitBash) {
    Say "Git Bash not found. Install Git for Windows first:" 'Red'
    Say "  winget install --id Git.Git -e"
    throw 'Git Bash missing.'
}
# git.exe needed only for clone/update path
if (-not $LocalSource -and -not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
    Say "git.exe not on PATH. Open a new terminal after installing Git, then retry." 'Red'
    throw 'git missing.'
}

# Clone, update, or install from local copy.
if ($LocalSource -and ($LocalSource -ne $InstallDir)) {
    Say "Installing from local copy: $LocalSource"
    if (Test-Path $InstallDir) {
        # Wipe stale install dir (but preserve user data: ~/.cc-remote/config.ini, servers.conf, history-downloads)
        Get-ChildItem -LiteralPath $InstallDir -Force | Where-Object {
            $_.Name -notin @('config.ini', 'servers.conf', 'history-downloads')
        } | Remove-Item -Recurse -Force
    } else {
        New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    }
    # Copy needed contents (avoid copying junk like .git if present).
    $items = @('src', '安装 Windows.bat', '安装 macOS.command', '打开 CC Switch Remote.bat', '使用说明.md')
    foreach ($it in $items) {
        $src = Join-Path $LocalSource $it
        if (Test-Path $src) { Copy-Item -LiteralPath $src -Destination $InstallDir -Recurse -Force }
    }
} elseif (Test-Path (Join-Path $InstallDir '.git')) {
    Say "Updating $InstallDir"
    git -C $InstallDir fetch --depth 1 origin $Branch | Out-Null
    git -C $InstallDir reset --hard "origin/$Branch" | Out-Null
} elseif ((Test-Path $InstallDir) -and -not $LocalSource) {
    throw "$InstallDir exists and is not a git checkout. Remove it or set `$env:CCR_INSTALL_DIR."
} elseif (-not $LocalSource) {
    Say "Cloning into $InstallDir"
    git clone --depth 1 --branch $Branch $Repo $InstallDir | Out-Null
}
# else: already installed from same location, no-op.

# Write launcher .bat with baked-in Git Bash path.
$batPath = Join-Path $InstallDir '打开 CC Switch Remote.bat'
@"
@echo off
setlocal
title CC Switch Remote
set "APP_ROOT=%~dp0"
set "APP_ROOT=%APP_ROOT:~0,-1%"
set "APP_ROOT_UNIX=%APP_ROOT:\=/%"
set "GIT_BASH=$gitBash"
if not exist "%APP_ROOT%\src\bin\cc-remote" (
    echo [ERROR] src\bin\cc-remote not found.
    pause
    exit /b 1
)
if "%CCR_LOGIN_SHELL%"=="1" (
    "%GIT_BASH%" --login -i -c "exec '%APP_ROOT_UNIX%/src/bin/cc-remote' %*"
) else (
    "%GIT_BASH%" -c "exec '%APP_ROOT_UNIX%/src/bin/cc-remote' %*"
)
exit /b %ERRORLEVEL%
"@ | Set-Content -LiteralPath $batPath -Encoding ASCII

# Add to User PATH (silent if already present).
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if (-not ($userPath -split ';' | Where-Object { $_ -eq $InstallDir })) {
    [Environment]::SetEnvironmentVariable('Path', "$userPath;$InstallDir".TrimStart(';'), 'User')
    Say "Added to User PATH (open new terminal)."
}

# Desktop + Start Menu shortcut.
$shortcut = Join-Path $InstallDir 'src\tools\create-shortcut.ps1'
if (Test-Path $shortcut) { & powershell -NoProfile -ExecutionPolicy Bypass -File $shortcut | Out-Host }

Say "`nDone. Starting first-time setup. Later, double-click 'CC Switch Remote' on your Desktop." 'Green'

if (-not $env:CCR_NO_LAUNCH) {
    Start-Process -FilePath $batPath -ArgumentList 'setup'
}
