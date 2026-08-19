[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 180
)

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$httpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
$healthUrl = "http://localhost:$httpPort/api/health"

try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host 'Training API plugin is already active.'
        exit 0
    }
}
catch {
    $responseProperty = $_.Exception.PSObject.Properties['Response']
    if ($null -ne $responseProperty -and $null -ne $responseProperty.Value -and [int]$responseProperty.Value.StatusCode -ne 404) {
        Write-Verbose $_.Exception.Message
    }
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("commerce-lab-plugin-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
$pluginsFile = Join-Path $temporaryRoot 'plugins.json'

try {
    $copyArguments = @(Get-ComposeArguments) + @('cp', 'app:/app/App_Data/plugins.json', $pluginsFile)
    $pluginsDeadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $plugins = $null
    $lastReadinessError = $null

    do {
        $copyOutput = & docker @copyArguments 2>&1
        $copyExitCode = $LASTEXITCODE
        if ($copyExitCode -eq 0) {
            try {
                $plugins = Get-Content -LiteralPath $pluginsFile -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
                if ($null -eq $plugins) {
                    throw 'The copied file does not contain a JSON value.'
                }
                break
            }
            catch {
                $lastReadinessError = "The copied file is not ready JSON: $($_.Exception.Message)"
            }
        }
        else {
            $copyError = ($copyOutput | Out-String).Trim()
            if ($copyError -notmatch '(?i)Could not find the file /app/App_Data/plugins\.json') {
                throw "docker compose cp failed with exit code $copyExitCode while reading plugins.json: $copyError"
            }
            $lastReadinessError = $copyError
        }

        if ([DateTime]::UtcNow -lt $pluginsDeadline) {
            Start-Sleep -Seconds 3
        }
    } while ([DateTime]::UtcNow -lt $pluginsDeadline)

    if ($null -eq $plugins) {
        throw "/app/App_Data/plugins.json did not become available as valid JSON within $TimeoutSeconds seconds. Last readiness error: $lastReadinessError"
    }

    $installed = @($plugins.InstalledPlugins | Where-Object { $_.SystemName -eq 'Training.Api' })
    $pending = @($plugins.PluginNamesToInstall | Where-Object { $_.Item1 -eq 'Training.Api' })
    if ($installed.Count -eq 0 -and $pending.Count -eq 0) {
        $plugins.PluginNamesToInstall = @($plugins.PluginNamesToInstall | Where-Object { $null -ne $_ }) + [pscustomobject]@{
            Item1 = 'Training.Api'
            Item2 = $null
        }
        $plugins | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $pluginsFile -Encoding UTF8
        Invoke-DockerCompose -Arguments @('cp', $pluginsFile, 'app:/app/App_Data/plugins.json')
    }

    Invoke-DockerCompose -Arguments @('restart', 'app')

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    do {
        try {
            $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Host 'Training API plugin installed and active.'
                exit 0
            }
        }
        catch {
            Write-Verbose $_.Exception.Message
        }
        Start-Sleep -Seconds 3
    } while ([DateTime]::UtcNow -lt $deadline)

    throw "Training API did not become ready within $TimeoutSeconds seconds."
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
