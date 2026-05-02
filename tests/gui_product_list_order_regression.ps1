$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -match 'Sort-Object Priority, Name') {
    Write-Error 'Expected product list to preserve discovery order so it matches the source batch scan output.'
}

if ($content -notmatch '(?s)\$script:ScannedProducts\s*=\s*@\(\$products\).*?foreach\s*\(\$p in \$script:ScannedProducts\)') {
    Write-Error 'Expected product list rendering to use discovery order from the collected scan results.'
}

Write-Host 'GUI product list order regression check passed.'
