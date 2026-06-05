$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch '(?s)function\s+Run-BatCommand\s*\{.*?Start-Process\s+-FilePath\s+"cmd\.exe"\s+-ArgumentList\s+@\(.*?/c.*?\$command.*?\).*?-PassThru') {
    Write-Error 'Expected Run-BatCommand to launch cmd.exe with Start-Process -PassThru so the Stop button can track the native process.'
}

if ($content -notmatch '(?s)function\s+Run-BatCommand\s*\{.*?"PID\|\$\(\$process\.Id\)"') {
    Write-Error 'Expected Run-BatCommand job to emit the native cmd.exe PID.'
}

if ($content -notmatch '(?s)function\s+Run-BatCommand\s*\{.*?"PID\|0"') {
    Write-Error 'Expected Run-BatCommand job to clear the tracked native process id when it exits.'
}

if ($content -notmatch '(?s)function\s+Run-BatCommand\s*\{.*?\$text\s+-like\s+''PID\|\*''.*?\$script:CurrentChildProcessId\s*=\s*\[int\]\$text\.Substring\(4\)') {
    Write-Error 'Expected Run-BatCommand UI callback to store emitted native process ids for Stop-TrackedChildProcess.'
}

if ($content -notmatch '(?s)function\s+Stop-TrackedChildProcess\s*\{.*?taskkill\.exe.*?/T.*?/F.*?/PID') {
    Write-Error 'Expected Stop-TrackedChildProcess to terminate the tracked native process tree.'
}

if ($content -notmatch '(?s)function\s+Run-BatCommand\s*\{.*?\. \$emitOutput' -or $content -match '(?s)function\s+Run-BatCommand\s*\{.*?& \$emitOutput') {
    Write-Error 'Expected Run-BatCommand to dot-source output polling so the file position cursor is preserved.'
}

Write-Host 'GUI bat command stop tracking regression check passed.'
