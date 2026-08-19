Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TrainingRoot {
    return (Split-Path -Parent $PSScriptRoot)
}

function Import-TrainingEnvironment {
    $trainingRoot = Get-TrainingRoot
    $environmentFile = Join-Path $trainingRoot '.env'
    if (-not (Test-Path -LiteralPath $environmentFile)) {
        throw "Missing $environmentFile. Run training/scripts/bootstrap.ps1 first."
    }

    foreach ($line in Get-Content -LiteralPath $environmentFile -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) {
            continue
        }

        $parts = $trimmed.Split('=', 2)
        if ($parts.Count -ne 2) {
            throw "Invalid environment line: $line"
        }

        [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1], 'Process')
    }

    $database = [Environment]::GetEnvironmentVariable('TRAINING_DATABASE')
    if ($database -ne 'CommerceEngineeringLab') {
        throw "Refusing to target database '$database'; training scripts are restricted to CommerceEngineeringLab."
    }

    if ([string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable('TRAINING_API_KEY'))) {
        throw 'TRAINING_API_KEY is required.'
    }
}

function Get-ComposeArguments {
    $trainingRoot = Get-TrainingRoot
    return @(
        'compose',
        '--project-name', 'commerce-engineering-lab',
        '--env-file', (Join-Path $trainingRoot '.env'),
        '--file', (Join-Path $trainingRoot 'compose.yml')
    )
}

function Invoke-DockerCompose {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $dockerArguments = @(Get-ComposeArguments) + $Arguments
    & docker @dockerArguments
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose failed with exit code $LASTEXITCODE"
    }
}

function Get-WebResponseUri {
    param([Parameter(Mandatory)]$Response)

    if ($Response.BaseResponse.PSObject.Properties.Name -contains 'RequestMessage') {
        return $Response.BaseResponse.RequestMessage.RequestUri
    }

    return $Response.BaseResponse.ResponseUri
}
