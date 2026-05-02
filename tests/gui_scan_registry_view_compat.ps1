$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch 'Is64BitOperatingSystem') {
    Write-Error 'Expected AutodeskUninstallerGUI.ps1 to gate registry view scanning on Environment.Is64BitOperatingSystem for compatibility.'
}

if ($content -match 'foreach\s*\(\$view in @\(\[Microsoft\.Win32\.RegistryView\]::Registry64,\s*\[Microsoft\.Win32\.RegistryView\]::Registry32\)\)') {
    Write-Error 'Expected AutodeskUninstallerGUI.ps1 to avoid unconditional Registry64 + Registry32 scanning.'
}

Write-Host 'GUI registry view compatibility regression check passed.'
