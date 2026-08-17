[CmdletBinding()]
param()

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
. (Join-Path $repositoryRoot 'training/scripts/_task-common.ps1')

try {
    Invoke-TaskScenario reset TRN-001
    Invoke-TaskScenario apply TRN-001

    Set-TaskFaultProfile database-transient | Out-Null
    $transient = Invoke-TaskApiRequest -Path '/api/products/1' -ExpectedStatus 200
    if ($transient.Headers['X-Training-Fault-Attempts'] -ne '3') {
        throw "Transient read must complete in exactly three attempts; received $($transient.Headers['X-Training-Fault-Attempts'])."
    }

    Set-TaskFaultProfile database-permanent | Out-Null
    Invoke-TaskApiRequest -Path '/api/products/1' -ExpectedStatus 500 | Out-Null

    Set-TaskFaultProfile none | Out-Null
    Invoke-TaskApiRequest -Path '/api/products/2147483647' -ExpectedStatus 404 | Out-Null
    Invoke-TaskScenario verify TRN-001
    Write-Host 'TRN-001 visible verification passed.'
}
finally {
    Set-TaskFaultProfile none | Out-Null
}
