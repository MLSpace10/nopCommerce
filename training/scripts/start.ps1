[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment
Ensure-RuntimeAppSettings
Invoke-DockerCompose -Arguments @('--profile', 'core', 'up', '--detach', '--build')

