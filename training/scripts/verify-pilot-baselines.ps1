[CmdletBinding()]
param(
    [ValidateRange(1, 10)][int]$Repetitions = 3
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_task-common.ps1')
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path

$expectedVisibleFailure = @{
    'TRN-001' = 'Expected HTTP 200 for GET /api/products/1; received 500'
    'TRN-003' = 'Expected HTTP 200 for GET /api/products/1/details; received 404'
    'TRN-012' = 'Sequential replay created orders'
}

try {
    foreach ($taskId in @('TRN-001', 'TRN-003', 'TRN-012')) {
        foreach ($run in 1..$Repetitions) {
            Write-Host "Reproducing $taskId baseline ($run/$Repetitions)..."
            & (Join-Path $repositoryRoot "training/tasks/$taskId/reproduce.ps1")
        }

        $visiblePassed = $false
        try {
            & (Join-Path $repositoryRoot "training/tasks/$taskId/visible-tests/verify.ps1")
            $visiblePassed = $true
        }
        catch {
            if ($_.Exception.Message -notlike "*$($expectedVisibleFailure[$taskId])*") {
                throw "${taskId} visible test failed for an unexpected reason: $($_.Exception.Message)"
            }
            Write-Host "$taskId visible test failed at the intended acceptance boundary."
        }

        if ($visiblePassed) {
            throw "$taskId visible test unexpectedly passed on its baseline."
        }
    }

    Write-Host "All three pilot baselines reproduced $Repetitions time(s) and failed their visible tests as expected."
}
finally {
    Set-TaskFaultProfile none | Out-Null
    foreach ($taskId in @('TRN-001', 'TRN-003', 'TRN-012')) {
        Invoke-TaskScenario reset $taskId
    }
}
