[CmdletBinding()]
param()

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
. (Join-Path $repositoryRoot 'training/scripts/_task-common.ps1')

Invoke-TaskScenario reset TRN-003
Invoke-TaskScenario apply TRN-003
Invoke-TaskApiRequest -Path '/api/products?pageSize=1' -ExpectedStatus 200 | Out-Null

$details = Invoke-TaskApiRequest -Path '/api/products/1/details' -ExpectedStatus 200
$model = $details.Body | ConvertFrom-Json
if ($model.id -ne 1 -or [string]::IsNullOrWhiteSpace($model.name) -or [string]::IsNullOrWhiteSpace($model.sku)) {
    throw 'Product details identity mapping is invalid.'
}
if ($null -ne $model.gtin) {
    throw 'Synthetic product 1 GTIN must be serialized as null.'
}
if ($null -eq $model.stockQuantity -or @($model.categoryIds).Count -lt 1) {
    throw 'Product details must include inventory and category data.'
}

Invoke-TaskApiRequest -Path '/api/products/2147483647/details' -ExpectedStatus 404 | Out-Null
Invoke-TaskApiRequest -Path '/api/products/0/details' -ExpectedStatus 404 | Out-Null
Invoke-TaskApiRequest -Path '/api/products/-1/details' -ExpectedStatus 404 | Out-Null
$runtimeContract = (Invoke-TaskApiRequest -Path '/api/openapi.yaml' -ExpectedStatus 200).Body -replace "`r`n", "`n"
$sourceContract = (Get-Content (Join-Path $repositoryRoot 'training/spec/openapi.yaml') -Raw) -replace "`r`n", "`n"
if ($runtimeContract.TrimEnd() -ne $sourceContract.TrimEnd()) {
    throw 'Runtime OpenAPI differs from training/spec/openapi.yaml.'
}
& (Join-Path $repositoryRoot 'training/scripts/verify-contract.ps1')
Invoke-TaskScenario verify TRN-003
Write-Host 'TRN-003 visible verification passed.'
