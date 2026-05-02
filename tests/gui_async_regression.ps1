$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

$taskRunMatches = [regex]::Matches($content, '\[System\.Threading\.Tasks\.Task\]::Run\(').Count
if ($taskRunMatches -gt 0) {
    Write-Error "Expected AutodeskUninstallerGUI.ps1 to avoid Task.Run-based async work, but found $taskRunMatches occurrence(s)."
}

if ($content -notmatch 'Start-Job') {
    Write-Error 'Expected AutodeskUninstallerGUI.ps1 to use Start-Job for WinPS-compatible background work.'
}

Write-Host 'GUI async regression check passed.'
