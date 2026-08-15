[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment
Invoke-DockerCompose -Arguments @('--profile', 'core', 'down', '--remove-orphans')
