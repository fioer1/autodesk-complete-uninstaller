$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -match 'Sort-Object Priority, Name') {
    Write-Error 'Expected GUI scan results to preserve source scan discovery order instead of resorting by Priority and Name.'
}

if ($content -notmatch '(?s)function\s+Get-AutodeskProductsFromRegistryPath\s*\{.*?\[bool\]\$DeduplicateByName') {
    Write-Error 'Expected registry scan helper to support source-compatible per-pass deduplication.'
}

if ($content -notmatch '(?s)foreach\s*\(\$regPathInfo in Get-UninstallRegistryPaths\).*?DeduplicateByName \$regPathInfo\.DeduplicateByName') {
    Write-Error 'Expected scan loop to pass per-path deduplication behavior matching the source batch script.'
}

Write-Host 'GUI scan source parity regression check passed.'
