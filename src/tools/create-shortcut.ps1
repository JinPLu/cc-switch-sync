# tools/create-shortcut.ps1 — create Desktop + Start Menu shortcuts to cc-remote.
#
# Run once after cloning (or via install.ps1). Safe to re-run.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\tools\create-shortcut.ps1
#
# Removes shortcuts if you pass -Uninstall.

param(
    [switch]$Uninstall,
    [string]$Name = 'CC Switch Remote'
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$Bat  = Join-Path $Root '打开 CC Switch Remote.bat'

if (-not (Test-Path $Bat)) {
    Write-Host "[ERROR] launcher not found at $Bat" -ForegroundColor Red
    exit 1
}

$Desktop   = [Environment]::GetFolderPath('Desktop')
$StartMenu = [Environment]::GetFolderPath('Programs')

$Targets = @(
    @{ Path = Join-Path $Desktop   "$Name.lnk"; Label = 'Desktop' },
    @{ Path = Join-Path $StartMenu "$Name.lnk"; Label = 'Start Menu' }
)

if ($Uninstall) {
    foreach ($t in $Targets) {
        if (Test-Path $t.Path) {
            Remove-Item -LiteralPath $t.Path -Force
            Write-Host (" - removed " + $t.Label + ": " + $t.Path)
        }
    }
    Write-Host "Shortcuts removed." -ForegroundColor Green
    exit 0
}

$wsh = New-Object -ComObject WScript.Shell
foreach ($t in $Targets) {
    $shortcut = $wsh.CreateShortcut($t.Path)
    $shortcut.TargetPath       = $Bat
    $shortcut.WorkingDirectory = $Root
    $shortcut.Description      = 'CC Switch Remote Kit — sync Claude Code / Codex config to remote Linux servers'
    # Use a recognizable icon from shell32.dll (network/globe).
    $shortcut.IconLocation     = "$env:SystemRoot\System32\shell32.dll,13"
    $shortcut.WindowStyle      = 1
    $shortcut.Save()
    Write-Host (" + " + $t.Label + ": " + $t.Path) -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Double-click the icon on your Desktop to launch." -ForegroundColor Cyan
