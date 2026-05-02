$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch 'GetValue\(' -and $content -notmatch '\[Microsoft\.Win32\.RegistryKey\]::OpenBaseKey') {
    Write-Error 'Expected AutodeskUninstallerGUI.ps1 to use a fast registry scan path based on RegistryKey.GetValue or OpenBaseKey.'
}

$scanBodyMatch = [regex]::Match(
    $content,
    'function\s+Scan-Products\s*\{[\s\S]*?Start-PolledJob\s+-JobScript\s*\{(?<body>[\s\S]*?)\}\s+-IntervalMs',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
)

if (-not $scanBodyMatch.Success) {
    Write-Error 'Could not locate the Scan-Products job body.'
}

$scanBody = $scanBodyMatch.Groups['body'].Value
if ($scanBody -match 'Get-ItemProperty') {
    Write-Error 'Expected Scan-Products background scan to avoid per-key Get-ItemProperty calls.'
}

Write-Host 'GUI scan performance regression check passed.'
