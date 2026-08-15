[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 300
)

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$httpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
$baseUrl = "http://localhost:$httpPort/"
$probeUrl = "${baseUrl}favicon.ico"
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
$lastError = $null

do {
    try {
        $probe = Invoke-WebRequest -Uri $probeUrl -MaximumRedirection 0 -TimeoutSec 10 -UseBasicParsing
        if ($probe.StatusCode -eq 200) {
            $response = Invoke-WebRequest -Uri $baseUrl -MaximumRedirection 5 -TimeoutSec 10 -UseBasicParsing
            $responseUri = Get-WebResponseUri -Response $response
            if ($response.StatusCode -ne 200 -or $responseUri.AbsolutePath -like '/install*') {
                $lastError = "HTTP $($response.StatusCode), final path $($responseUri.AbsolutePath)"
                Start-Sleep -Seconds 3
                continue
            }

            Write-Host "HTTP ready: $($response.StatusCode) $responseUri (side-effect-free probe: $probeUrl)"
            Invoke-DockerCompose -Arguments @('ps')
            exit 0
        }
        $lastError = "Probe returned HTTP $($probe.StatusCode)"
    }
    catch {
        $lastError = $_.Exception.Message
    }

    Start-Sleep -Seconds 3
} while ([DateTime]::UtcNow -lt $deadline)

Invoke-DockerCompose -Arguments @('ps')
throw "Platform did not become ready within $TimeoutSeconds seconds. Last result: $lastError"
