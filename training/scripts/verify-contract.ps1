[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$trainingRoot = Get-TrainingRoot
$specRoot = Join-Path $trainingRoot 'spec'
$generatedRoot = Join-Path $specRoot '.generated'
$generatedContract = Join-Path $specRoot 'generated/openapi.json'
$currentContract = Join-Path $generatedRoot 'openapi.json'
$baselinePath = Join-Path $specRoot 'compatibility-baseline.json'

New-Item -ItemType Directory -Path $generatedRoot -Force | Out-Null

Invoke-DockerCompose -Arguments @('--profile', 'contract', 'run', '--rm', 'contract',
    'lint', 'openapi.yaml', '--config=redocly.yaml', '--max-problems=100')
Invoke-DockerCompose -Arguments @('--profile', 'contract', 'run', '--rm', 'contract',
    'bundle', 'openapi.yaml', '--output=.generated/openapi.json')

if (-not (Test-Path -LiteralPath $generatedContract)) {
    throw "Missing generated contract: $generatedContract"
}

$expectedHash = (Get-FileHash -LiteralPath $generatedContract -Algorithm SHA256).Hash
$actualHash = (Get-FileHash -LiteralPath $currentContract -Algorithm SHA256).Hash
if ($expectedHash -ne $actualHash) {
    throw 'Generated OpenAPI drift detected. Regenerate training/spec/generated/openapi.json intentionally.'
}

$contract = Get-Content -LiteralPath $currentContract -Raw -Encoding UTF8 | ConvertFrom-Json
$baseline = Get-Content -LiteralPath $baselinePath -Raw -Encoding UTF8 | ConvertFrom-Json

foreach ($operation in $baseline.operations) {
    $pathProperty = $contract.paths.PSObject.Properties[$operation.path]
    if ($null -eq $pathProperty) {
        throw "Backward compatibility failure: missing path $($operation.path)."
    }
    $methodProperty = $pathProperty.Value.PSObject.Properties[$operation.method]
    if ($null -eq $methodProperty) {
        throw "Backward compatibility failure: missing $($operation.method.ToUpperInvariant()) $($operation.path)."
    }
    $method = $methodProperty.Value
    if ($null -eq $method.responses.PSObject.Properties[$operation.successStatus]) {
        throw "Backward compatibility failure: missing response $($operation.successStatus) for $($operation.method.ToUpperInvariant()) $($operation.path)."
    }
}

foreach ($schemaEntry in $baseline.requiredSchemaProperties.PSObject.Properties) {
    $schemaProperty = $contract.components.schemas.PSObject.Properties[$schemaEntry.Name]
    if ($null -eq $schemaProperty) {
        throw "Backward compatibility failure: missing schema $($schemaEntry.Name)."
    }
    $schema = $schemaProperty.Value
    foreach ($property in $schemaEntry.Value) {
        if ($null -eq $schema.properties.PSObject.Properties[$property]) {
            throw "Backward compatibility failure: missing $($schemaEntry.Name).$property."
        }
    }
}

Write-Host "OpenAPI lint, contract build, generated drift, and compatibility checks passed ($actualHash)."
