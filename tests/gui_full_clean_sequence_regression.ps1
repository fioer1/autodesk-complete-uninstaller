$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$batPath = Join-Path $repoRoot 'autodesk_complete_uninstaller.bat'

$gui = Get-Content -Path $guiPath -Raw
$bat = Get-Content -Path $batPath -Raw

if ($gui -match '1`nX`n3') {
    Write-Error 'Expected GUI Full Clean to avoid the old scan-pause-menu sequence.'
}

if ($gui -notmatch '(?s)btnFullClean.*?Run-BatCommand\s+-InputSequence\s+"3`nYES`nN`nN`nN"') {
    Write-Error 'Expected GUI Full Clean to start directly with menu option 3.'
}

if ($bat -notmatch '(?s):full_clean.*?if !PROD_COUNT! equ 0 \(\s*echo\.\s*echo\s+No products scanned yet\. Scanning now before full clean\.\.\..*?set "AUTO_AFTER_SCAN=full_clean".*?goto :scan_products') {
    Write-Error 'Expected batch Full Clean to auto-scan when products have not been scanned yet.'
}

$autoScanPromptCount = ([regex]::Matches($bat, [regex]::Escape('No products scanned yet. Scanning now before full clean...'))).Count
if ($autoScanPromptCount -ne 1) {
    Write-Error "Expected exactly one Full Clean auto-scan prompt, found $autoScanPromptCount."
}

$uninstallSelectedBlock = [regex]::Match($bat, '(?ms)^:uninstall_selected\s*$.*?^:full_clean\s*$').Value
if ($uninstallSelectedBlock -match 'Scanning now before full clean') {
    Write-Error 'Expected Uninstall Selected to keep its own no-scan handling, not Full Clean auto-scan.'
}

if ($uninstallSelectedBlock -notmatch '(?s)No products scanned yet\. Run option \[1\] first\..*?pause\s*goto :main_menu') {
    Write-Error 'Expected Uninstall Selected to return to the main menu when no products have been scanned.'
}

if ($bat -notmatch '(?s)if !PROD_COUNT! equ 0 \(\s*echo\s+!CYLW!No Autodesk products detected.*?if /i "!AUTO_AFTER_SCAN!"=="full_clean" \(\s*set "AUTO_AFTER_SCAN=".*?exit /b 1') {
    Write-Error 'Expected auto Full Clean scan to stop safely when no products are detected.'
}

if ($bat -notmatch '(?s)echo\s+SCAN: !PROD_COUNT! products >> "!LOGFILE!".*?if /i "!AUTO_AFTER_SCAN!"=="full_clean" \(\s*set "AUTO_AFTER_SCAN=".*?goto :full_clean') {
    Write-Error 'Expected scan_products to continue directly into full_clean after an automatic Full Clean scan.'
}

Write-Host 'GUI full clean sequence regression check passed.'
