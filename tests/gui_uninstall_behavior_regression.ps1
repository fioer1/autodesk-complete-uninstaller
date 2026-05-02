$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch '\[LEGACY\].*Setup\.exe') {
    Write-Error 'Expected selective uninstall flow to handle Setup.exe uninstallers with a dedicated legacy branch.'
}

if ($content -match 'Start-Process\s+-FilePath\s+"cmd\.exe"\s+-ArgumentList\s+"/c\s+`"\$us`"\s+--mode unattended"') {
    Write-Error 'Expected generic uninstall command execution to avoid wrapping the full UninstallString in a single quoted cmd /c invocation.'
}

if ($content -notmatch '(?s)function\s+Uninstall-SelectedProducts\s*\{.*?RETRY_MAX\s*=\s*3') {
    Write-Error 'Expected selective uninstall flow to support retry passes after the initial uninstall pass.'
}

if ($content -notmatch '(?s)function\s+Uninstall-SelectedProducts\s*\{.*?PASS_NUM') {
    Write-Error 'Expected selective uninstall flow to report retry pass progress.'
}

if ($content -notmatch '(?s)\$script:CurrentChildProcessId\s*=\s*\$null') {
    Write-Error 'Expected GUI state to track the currently running native child process id.'
}

if ($content -notmatch '(?s)PID\|.*?\$script:CurrentChildProcessId') {
    Write-Error 'Expected background uninstall job to emit child process ids back to the UI state tracker.'
}

Write-Host 'GUI uninstall behavior regression check passed.'
