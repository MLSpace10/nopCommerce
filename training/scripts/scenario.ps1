[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('apply', 'reset', 'verify')]
    [string]$Operation,

    [Parameter(Mandatory, Position = 1)]
    [ValidatePattern('^TRN-[0-9]{3}$')]
    [string]$TaskId
)

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$trainingRoot = Get-TrainingRoot
$scenarioFile = Join-Path $trainingRoot "db/scenarios/$TaskId/$Operation.sql"
if (-not (Test-Path -LiteralPath $scenarioFile -PathType Leaf)) {
    throw "Scenario operation does not exist: $scenarioFile"
}

$database = [Environment]::GetEnvironmentVariable('TRAINING_DATABASE')
$saPassword = [Environment]::GetEnvironmentVariable('MSSQL_SA_PASSWORD')
$containerPath = "/training/db/scenarios/$TaskId/$Operation.sql"

Invoke-DockerCompose -Arguments @(
    'run', '--rm', '--no-deps',
    '-e', "MSSQL_SA_PASSWORD=$saPassword",
    '-e', "TRAINING_DATABASE=$database",
    '--entrypoint', '/bin/bash', 'seed', '-c',
    "/opt/mssql-tools18/bin/sqlcmd -C -S database -U sa -P `"`$MSSQL_SA_PASSWORD`" -d `"`$TRAINING_DATABASE`" -i $containerPath -b"
)

Write-Host "Scenario $TaskId $Operation completed against $database."
