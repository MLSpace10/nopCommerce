[CmdletBinding()]
param()

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
. (Join-Path $repositoryRoot 'training/scripts/_task-common.ps1')

Invoke-TaskScenario reset TRN-003
Invoke-TaskScenario apply TRN-003
Invoke-TaskApiRequest -Path '/api/products?pageSize=1' -ExpectedStatus 200 | Out-Null
$details = Invoke-TaskApiRequest -Path '/api/products/1/details' -ExpectedStatus 404

$sourceContract = Get-Content (Join-Path $repositoryRoot 'training/spec/openapi.yaml') -Raw
if ($sourceContract -match '(?m)^  /api/products/\{productId\}/details:') {
    throw 'TRN-003 source contract unexpectedly already contains the requested route.'
}

Invoke-TaskScenario verify TRN-003
Write-Host "TRN-003 reproduced: collection HTTP 200, requested details endpoint HTTP $($details.Status)."
