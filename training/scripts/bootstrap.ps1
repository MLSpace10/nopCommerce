[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')

$trainingRoot = Get-TrainingRoot
$environmentFile = Join-Path $trainingRoot '.env'
$environmentExample = Join-Path $trainingRoot '.env.example'

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker CLI is required.'
}

docker info *> $null
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Engine is not reachable. Start Docker Desktop and retry.'
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw '.NET SDK is required.'
}

$sdkVersion = [Version]((dotnet --version).Split('-')[0])
if ($sdkVersion.Major -lt 10) {
    throw ".NET SDK 10 or later is required; found $sdkVersion."
}

if (-not (Test-Path -LiteralPath $environmentFile)) {
    Copy-Item -LiteralPath $environmentExample -Destination $environmentFile
    Write-Host "Created local configuration: $environmentFile"
}

Import-TrainingEnvironment
Ensure-RuntimeAppSettings

& (Join-Path $PSScriptRoot 'start.ps1')
& (Join-Path $PSScriptRoot 'health.ps1')
& (Join-Path $PSScriptRoot 'verify-platform.ps1')

$httpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
Write-Host "Commerce Engineering Lab is ready: http://localhost:$httpPort"
Write-Host 'Training API documentation will be added in Phase 2.'

