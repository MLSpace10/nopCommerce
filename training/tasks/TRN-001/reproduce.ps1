[CmdletBinding()]
param()

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
. (Join-Path $repositoryRoot 'training/scripts/_task-common.ps1')

try {
    Invoke-TaskScenario reset TRN-001
    Invoke-TaskScenario apply TRN-001
    Set-TaskFaultProfile database-transient | Out-Null

    $response = Invoke-TaskApiRequest -Path '/api/products/1'
    if ($response.Status -ne 500) {
        throw "Expected the baseline defect to return HTTP 500; received $($response.Status)."
    }
    Invoke-TaskScenario verify TRN-001
    Write-Host 'TRN-001 reproduced: HTTP 500 after one transient read attempt.'
}
finally {
    Set-TaskFaultProfile none | Out-Null
}
