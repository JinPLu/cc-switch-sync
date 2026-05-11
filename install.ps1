# cc-switch-sync installer for Windows
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SyncDir = "$env:USERPROFILE\.cc-switch-sync"
$ScriptsDir = "$env:USERPROFILE\.cc-switch\scripts"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  cc-switch-sync Installer (Windows)"
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# 1. Create config directory
if (-not (Test-Path $SyncDir)) {
    New-Item -ItemType Directory -Path $SyncDir -Force | Out-Null
    Write-Host "  [+] Created $SyncDir" -ForegroundColor Green
}

# 2. Copy servers.example.json as template if no servers.json yet
if (-not (Test-Path "$SyncDir\servers.json")) {
    Copy-Item "$ScriptDir\examples\servers.example.json" "$SyncDir\servers.json"
    Write-Host "  [+] Created $SyncDir\servers.json (edit this with your servers)" -ForegroundColor Green
} else {
    Write-Host "  [=] $SyncDir\servers.json already exists, skipping" -ForegroundColor Yellow
}

# 3. Copy sync script to CC Switch scripts directory
if (-not (Test-Path $ScriptsDir)) {
    New-Item -ItemType Directory -Path $ScriptsDir -Force | Out-Null
}
Copy-Item "$ScriptDir\sync-to-server.bat" "$ScriptsDir\sync-to-server.bat" -Force
Write-Host "  [+] Installed sync-to-server.bat -> $ScriptsDir" -ForegroundColor Green

# 4. Add to PATH if not already there
$UserPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($UserPath -notlike "*$ScriptsDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$UserPath;$ScriptsDir", "User")
    Write-Host "  [+] Added $ScriptsDir to user PATH" -ForegroundColor Green
    Write-Host "      (restart terminal for PATH to take effect)" -ForegroundColor Yellow
} else {
    Write-Host "  [=] $ScriptsDir already in PATH" -ForegroundColor Yellow
}

# 5. Fix SSH permissions if needed
$SshConfig = "$env:USERPROFILE\.ssh\config"
if (Test-Path $SshConfig) {
    $acl = Get-Acl $SshConfig
    $accessRules = $acl.Access | Where-Object { $_.IdentityReference -notmatch $env:USERNAME }
    if ($accessRules.Count -gt 0) {
        Write-Host ""
        Write-Host "  [!] Fixing .ssh\config permissions (OpenSSH requirement)..." -ForegroundColor Yellow
        icacls $SshConfig /inheritance:r | Out-Null
        icacls $SshConfig /grant:r "$($env:USERNAME):F" | Out-Null
        Write-Host "  [+] .ssh\config permissions fixed" -ForegroundColor Green
    }
}

$SshKey = "$env:USERPROFILE\.ssh\id_rsa"
if (Test-Path $SshKey) {
    $acl = Get-Acl $SshKey
    $accessRules = $acl.Access | Where-Object { $_.IdentityReference -notmatch $env:USERNAME }
    if ($accessRules.Count -gt 0) {
        icacls $SshKey /inheritance:r | Out-Null
        icacls $SshKey /grant:r "$($env:USERNAME):F" | Out-Null
        Write-Host "  [+] .ssh\id_rsa permissions fixed" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Installation complete!"
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    1. Edit your server list:"
Write-Host "       notepad $SyncDir\servers.json" -ForegroundColor Cyan
Write-Host ""
Write-Host "    2. Open a NEW terminal, then run:"
Write-Host "       sync-to-server" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
