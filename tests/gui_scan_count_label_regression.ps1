$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$readmePath = Join-Path $repoRoot 'README.md'
$batPath = Join-Path $repoRoot 'autodesk_complete_uninstaller.bat'

$gui = Get-Content -Path $guiPath -Raw
$readme = Get-Content -Path $readmePath -Raw
$bat = Get-Content -Path $batPath -Raw

if ($bat -notmatch 'Final Verification.*16-point deep scan') {
    Write-Error 'Expected source batch menu to advertise 16-point final verification.'
}

if ($bat -notmatch '\[15/15\].*Hosts file') {
    Write-Error 'Expected source batch remnant search to contain 15 scan steps.'
}

if ($bat -notmatch '\[17/17\].*Hosts file') {
    Write-Error 'Expected source batch full audit to contain 17 audit steps.'
}

if ($bat -notmatch '\[10/10\].*Hosts file') {
    Write-Error 'Expected source batch Error 103 diagnostics to contain 10 diagnostic steps.'
}

if ($gui -notmatch '16 \u9879\u6df1\u5ea6\u7cfb\u7edf\u626b\u63cf') {
    Write-Error 'Expected GUI final verification header to advertise 16 scan points.'
}

if ($gui -notmatch '16 \u9879\u9a8c\u8bc1\u626b\u63cf') {
    Write-Error 'Expected GUI final verification status to advertise 16 scan points.'
}

if ($gui -notmatch '15 \u9879\u626b\u63cf') {
    Write-Error 'Expected GUI remnant search status to advertise 15 scan points.'
}

if ($gui -match '12 \u9879\u6df1\u5ea6\u7cfb\u7edf\u626b\u63cf|12 \u9879\u9a8c\u8bc1\u626b\u63cf|11 \u9879\u626b\u63cf') {
    Write-Error 'Expected GUI scan labels to avoid stale v5.5 scan counts.'
}

if ($readme -notmatch '16-point deep verification scan') {
    Write-Error 'Expected README features to advertise 16-point final verification.'
}

if ($readme -notmatch 'Final Verification.*16-point deep scan') {
    Write-Error 'Expected README menu option 5 to advertise 16-point final verification.'
}

if ($readme -notmatch '15-point full system scan') {
    Write-Error 'Expected README remnant search description to advertise 15-point scanning.'
}

if ($readme -notmatch '17-point read-only preview') {
    Write-Error 'Expected README full audit description to advertise 17-point auditing.'
}

if ($readme -notmatch '10-point diagnostic') {
    Write-Error 'Expected README Error 103 description to advertise 10 diagnostic points.'
}

if ($readme -notmatch 'Runs 16-point final verification') {
    Write-Error 'Expected README phase J description to advertise 16-point final verification.'
}

if ($readme -notmatch '\[7/16\]') {
    Write-Error 'Expected README troubleshooting references to use the current [7/16] verification step.'
}

if ($readme -match '12-point deep verification scan|12-point deep scan|Runs 12-point final verification|13-point read-only preview|9-point diagnostic|\[7/12\]') {
    Write-Error 'Expected README scan labels to avoid stale scan count wording.'
}

Write-Host 'GUI scan count label regression check passed.'
