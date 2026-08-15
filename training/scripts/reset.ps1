[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$trainingRoot = (Resolve-Path -LiteralPath (Get-TrainingRoot)).Path
$composeFile = (Join-Path $trainingRoot 'compose.yml' | Resolve-Path).Path

if (-not (Select-String -LiteralPath $composeFile -Pattern '^name: commerce-engineering-lab$' -Quiet)) {
    throw 'Refusing reset: the Compose project identity is not the expected training-only project.'
}

Invoke-DockerCompose -Arguments @('--profile', 'core', 'down', '--volumes', '--remove-orphans')

$appSettingsFile = Join-Path $trainingRoot 'runtime/App_Data/appsettings.json'
[IO.File]::WriteAllText($appSettingsFile, '{}', [Text.UTF8Encoding]::new($false))

& (Join-Path $PSScriptRoot 'start.ps1')
& (Join-Path $PSScriptRoot 'health.ps1')
& (Join-Path $PSScriptRoot 'verify-platform.ps1')
