Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$script:TaskHttpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
$script:TaskApiKey = [Environment]::GetEnvironmentVariable('TRAINING_API_KEY')
$script:TaskBaseUrl = "http://localhost:$script:TaskHttpPort"
$script:TaskCurl = Get-Command curl.exe -ErrorAction SilentlyContinue
if ($null -eq $script:TaskCurl) {
    $script:TaskCurl = Get-Command curl -ErrorAction Stop
}

function Invoke-TaskApiRequest {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Method = 'GET',
        [string]$Body,
        [hashtable]$Headers = @{},
        [int]$ExpectedStatus,
        [double]$MaximumSeconds = 0,
        [switch]$AllowCurlFailure
    )

    $temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("commerce-lab-task-http-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $bodyFile = Join-Path $temporaryRoot 'body'
    $headerFile = Join-Path $temporaryRoot 'headers'

    try {
        $arguments = @('--silent', '--show-error', '--output', $bodyFile, '--dump-header', $headerFile,
            '--write-out', '%{http_code}', '--request', $Method,
            '--header', "X-Training-Api-Key: $script:TaskApiKey")
        foreach ($header in $Headers.GetEnumerator()) {
            $arguments += @('--header', "$($header.Key): $($header.Value)")
        }
        if ($Body) {
            $arguments += @('--header', 'Content-Type: application/json', '--data-binary', $Body)
        }
        if ($MaximumSeconds -gt 0) {
            $arguments += @('--max-time', $MaximumSeconds.ToString([Globalization.CultureInfo]::InvariantCulture))
        }
        $arguments += "$script:TaskBaseUrl$Path"

        $statusText = (& $script:TaskCurl.Source @arguments | Out-String).Trim()
        $curlExitCode = $LASTEXITCODE
        if ($curlExitCode -ne 0 -and -not $AllowCurlFailure) {
            throw "curl failed for $Method $Path with exit code $curlExitCode."
        }

        $status = if ($statusText -match '^[0-9]{3}$') { [int]$statusText } else { 0 }
        if ($PSBoundParameters.ContainsKey('ExpectedStatus') -and $status -ne $ExpectedStatus) {
            $responseBody = if (Test-Path $bodyFile) { Get-Content $bodyFile -Raw } else { '' }
            throw "Expected HTTP $ExpectedStatus for $Method $Path; received $status. Body: $responseBody"
        }

        $responseHeaders = @{}
        if (Test-Path $headerFile) {
            foreach ($line in Get-Content $headerFile) {
                if ($line -match '^([^:]+):\s*(.*)$') {
                    $responseHeaders[$matches[1].Trim()] = $matches[2].Trim()
                }
            }
        }

        return [pscustomobject]@{
            Status = $status
            Body = if (Test-Path $bodyFile) { Get-Content $bodyFile -Raw } else { '' }
            Headers = $responseHeaders
            CurlExitCode = $curlExitCode
        }
    }
    finally {
        if (Test-Path $temporaryRoot) {
            Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
        }
    }
}

function Set-TaskFaultProfile {
    param([Parameter(Mandatory)][string]$Profile)

    return Invoke-TaskApiRequest -Path "/api/internal/training/faults/$Profile" -Method POST -ExpectedStatus 200
}

function Invoke-TaskScenario {
    param(
        [Parameter(Mandatory)][ValidateSet('apply', 'reset', 'verify')][string]$Operation,
        [Parameter(Mandatory)][ValidatePattern('^TRN-[0-9]{3}$')][string]$TaskId
    )

    & (Join-Path $PSScriptRoot 'scenario.ps1') $Operation $TaskId
}

function Invoke-TaskSqlFile {
    param(
        [Parameter(Mandatory)][ValidatePattern('^TRN-[0-9]{3}$')][string]$TaskId,
        [Parameter(Mandatory)][ValidatePattern('^[a-z0-9-]+\.sql$')][string]$File,
        [hashtable]$Variables = @{}
    )

    $database = [Environment]::GetEnvironmentVariable('TRAINING_DATABASE')
    $saPassword = [Environment]::GetEnvironmentVariable('MSSQL_SA_PASSWORD')
    $sqlArguments = @('/opt/mssql-tools18/bin/sqlcmd', '-C', '-S', 'database', '-U', 'sa',
        '-P', '"$MSSQL_SA_PASSWORD"', '-d', '"$TRAINING_DATABASE"',
        '-i', "/training/db/scenarios/$TaskId/$File", '-b')
    if ($Variables.Count -gt 0) {
        $sqlArguments += '-v'
        foreach ($variable in $Variables.GetEnumerator()) {
            if ($variable.Key -notmatch '^[A-Za-z][A-Za-z0-9]*$' -or
                $variable.Value.ToString() -notmatch '^[A-Za-z0-9._:-]+$') {
                throw "Unsafe SQLCMD variable: $($variable.Key)"
            }
            $sqlArguments += "`"$($variable.Key)=$($variable.Value)`""
        }
    }

    Invoke-DockerCompose -Arguments @(
        'run', '--rm', '--no-deps',
        '-e', "MSSQL_SA_PASSWORD=$saPassword",
        '-e', "TRAINING_DATABASE=$database",
        '--entrypoint', '/bin/bash', 'seed', '-c',
        ($sqlArguments -join ' ')
    )
}
