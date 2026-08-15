[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$httpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
$database = [Environment]::GetEnvironmentVariable('TRAINING_DATABASE')
$saPassword = [Environment]::GetEnvironmentVariable('MSSQL_SA_PASSWORD')

$response = Invoke-WebRequest -Uri "http://localhost:$httpPort/" -MaximumRedirection 5 -TimeoutSec 30 -UseBasicParsing
if ($response.StatusCode -ne 200) {
    throw "Unexpected application status: $($response.StatusCode)"
}

Invoke-DockerCompose -Arguments @(
    'run', '--rm', '--no-deps',
    '-e', "MSSQL_SA_PASSWORD=$saPassword",
    '-e', "TRAINING_DATABASE=$database",
    '--entrypoint', '/bin/bash', 'seed', '-c',
    '/opt/mssql-tools18/bin/sqlcmd -C -S database -U sa -P "$MSSQL_SA_PASSWORD" -d "$TRAINING_DATABASE" -v "TrainingDatabase=$TRAINING_DATABASE" -i /training/db/assertions/platform.sql -b'
)

$redisResult = Invoke-DockerCompose -Arguments @('exec', '--no-TTY', 'redis', 'redis-cli', 'ping') 6>&1
if (($redisResult | Out-String).Trim() -notmatch 'PONG') {
    throw 'Redis did not return PONG.'
}

Write-Host "Verified HTTP 200, SQL persisted state, and Redis PONG."
