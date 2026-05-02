$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$guiPath = Join-Path $repoRoot 'AutodeskUninstallerGUI.ps1'
$content = Get-Content -Path $guiPath -Raw

if ($content -notmatch '<GridViewRowPresenter') {
    Write-Error 'Expected lvProducts ListViewItem template to use GridViewRowPresenter so GridView columns render correctly.'
}

if ($content -match '<ListView\.ItemContainerStyle>[\s\S]*?<ContentPresenter\s*/>[\s\S]*?</ListView\.ItemContainerStyle>') {
    Write-Error 'Expected lvProducts ListViewItem template to avoid plain ContentPresenter-only rendering.'
}

Write-Host 'GUI products GridView template regression check passed.'
