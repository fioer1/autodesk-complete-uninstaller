$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch '(?s)function\s+Scan-Products\s*\{.*?\$scanOnData\s*=\s*\{.*?\}\.GetNewClosure\(\).*?Start-PolledJob.*?-OnData\s+\$scanOnData') {
    Write-Error 'Expected Scan-Products OnData callback to preserve async state with GetNewClosure().'
}

if ($content -notmatch '(?s)function\s+Scan-Products\s*\{.*?\$scanOnCompleted\s*=\s*\{.*?\}\.GetNewClosure\(\).*?Start-PolledJob.*?-OnCompleted\s+\$scanOnCompleted') {
    Write-Error 'Expected Scan-Products OnCompleted callback to preserve async state with GetNewClosure().'
}

if ($content -notmatch '(?s)function\s+Uninstall-SelectedProducts\s*\{.*?\$uninstallOnData\s*=\s*\{.*?\}\.GetNewClosure\(\).*?Start-PolledJob.*?-OnData\s+\$uninstallOnData') {
    Write-Error 'Expected Uninstall-SelectedProducts OnData callback to preserve async state with GetNewClosure().'
}

if ($content -notmatch '(?s)function\s+Uninstall-SelectedProducts\s*\{.*?\$uninstallOnCompleted\s*=\s*\{.*?\}\.GetNewClosure\(\).*?Start-PolledJob.*?-OnCompleted\s+\$uninstallOnCompleted') {
    Write-Error 'Expected Uninstall-SelectedProducts OnCompleted callback to preserve async state with GetNewClosure().'
}

Write-Host 'GUI async callback closure regression check passed.'
