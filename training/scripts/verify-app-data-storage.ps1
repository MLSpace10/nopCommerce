[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$trainingRoot = Split-Path -Parent $PSScriptRoot
$compose = Get-Content -LiteralPath (Join-Path $trainingRoot 'compose.yml') -Raw
$scripts = @(
    '_common.ps1'
    'bootstrap.ps1'
    'start.ps1'
    'reset.ps1'
) | ForEach-Object {
    Get-Content -LiteralPath (Join-Path $PSScriptRoot $_) -Raw
}

if ($compose -notmatch '(?m)^\s+- app-data:/app/App_Data\s*$') {
    throw 'The app service must mount the app-data named volume at /app/App_Data.'
}

if ($compose -match '(?m)^\s+- .*appsettings\.json:/app/App_Data/appsettings\.json\s*$') {
    throw 'appsettings.json must not be bind-mounted from the host.'
}

if (($scripts -join "`n") -match 'Ensure-RuntimeAppSettings|runtime[/\\]App_Data[/\\]appsettings\.json') {
    throw 'Training lifecycle scripts must not create a host-side appsettings.json.'
}

$reset = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'reset.ps1') -Raw
if ($reset -notmatch "'down', '--volumes', '--remove-orphans'") {
    throw 'Reset must remove the training project volumes for a clean installation.'
}

$start = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'start.ps1') -Raw
if ($start -match "'down'|--volumes") {
    throw 'Normal start must preserve the app-data named volume.'
}

Write-Host 'App_Data named-volume storage checks passed.'
