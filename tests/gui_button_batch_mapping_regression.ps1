$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$batPath = Join-Path $repoRoot 'autodesk_complete_uninstaller.bat'

$gui = Get-Content -Path $guiPath -Raw
$bat = Get-Content -Path $batPath -Raw

function Assert-Contains {
    param(
        [string]$Text,
        [string]$Needle,
        [string]$Message
    )

    if (-not $Text.Contains($Needle)) {
        Write-Error $Message
    }
}

function Assert-NotContains {
    param(
        [string]$Text,
        [string]$Needle,
        [string]$Message
    )

    if ($Text.Contains($Needle)) {
        Write-Error $Message
    }
}

Assert-Contains $gui 'Run-BatCommand -InputSequence "3`nYES`nN`nN`nN"' 'Expected Full Clean GUI button to invoke batch menu option 3.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "4`nYES`nN`nN"' 'Expected Deep Clean GUI button to invoke batch menu option 4.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "5`n"' 'Expected Verify GUI button to invoke batch menu option 5.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "6`nY`nY"' 'Expected Restore Point GUI button to invoke batch menu option 6 and approve restore enablement if needed.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "7`n"' 'Expected Remnant Search GUI button to invoke batch menu option 7 without menu-navigation input.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "8`n"' 'Expected Full Audit GUI button to invoke batch menu option 8 without menu-navigation input.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "10`nN`nN`nN`nN`nN`nN`nN"' 'Expected Error 103 GUI button to invoke batch menu option 10 and decline repair prompts safely.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "11`n"' 'Expected Restart Pending GUI button to invoke batch menu option 11 without menu-navigation input.'
Assert-Contains $gui 'Run-BatCommand -InputSequence "12`nY"' 'Expected Backup Templates GUI button to invoke batch menu option 12 and approve backup.'

foreach ($badSequence in @(
    '6`nY`nX`n0',
    '7`nX`n0',
    '8`nX`n0',
    '10`nX`n0',
    '11`nX`n0',
    '12`nX`n0'
)) {
    Assert-NotContains $gui $badSequence "Expected GUI command sequences to avoid stale pause/menu-navigation input: $badSequence"
}

Assert-Contains $gui 'AUTODESK_GUI_MODE=1' 'Expected GUI batch commands to set AUTODESK_GUI_MODE=1.'
Assert-Contains $gui '| ( set `"AUTODESK_GUI_MODE=1`" & `"$CommandPath`" 2>&1 )' 'Expected GUI piped batch commands to set AUTODESK_GUI_MODE on the batch side of the pipe.'
Assert-Contains $bat 'AUTODESK_GUI_MODE' 'Expected batch script to recognize GUI one-shot mode.'

foreach ($pattern in @(
    '(?s):search_remnants.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*pause\s*goto :main_menu',
    '(?s):full_audit.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*pause\s*goto :main_menu',
    '(?s):fix_error103.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*pause\s*goto :main_menu',
    '(?s):fix_reboot_pending.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*pause\s*goto :main_menu',
    '(?s):backup_templates.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*pause\s*goto :main_menu',
    '(?s):run_verify.*?if /i "!AUTODESK_GUI_MODE!"=="1" exit /b 0\s*set /p "RET='
)) {
    if ($bat -notmatch $pattern) {
        Write-Error "Expected batch GUI one-shot exit pattern not found: $pattern"
    }
}

Write-Host 'GUI button to batch mapping regression check passed.'
