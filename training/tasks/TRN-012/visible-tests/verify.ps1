[CmdletBinding()]
param()

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
. (Join-Path $repositoryRoot 'training/scripts/_task-common.ps1')

function New-OrderBody([int]$Quantity) {
    return @{ customerId = 4; productId = 1; quantity = $Quantity } | ConvertTo-Json -Compress
}

function Invoke-ConcurrentOrders([string]$Key, [string]$Body) {
    $client = [Net.Http.HttpClient]::new()
    $client.DefaultRequestHeaders.Add('X-Training-Api-Key', $script:TaskApiKey)
    try {
        $requests = 1..2 | ForEach-Object {
            $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, "$script:TaskBaseUrl/api/orders")
            $request.Headers.Add('Idempotency-Key', $Key)
            $request.Content = [Net.Http.StringContent]::new($Body, [Text.Encoding]::UTF8, 'application/json')
            $request
        }
        $tasks = @($requests | ForEach-Object { $client.SendAsync($_) })
        $responses = @($tasks | ForEach-Object { $_.GetAwaiter().GetResult() })
        return @($responses | ForEach-Object {
            [pscustomobject]@{
                Status = [int]$_.StatusCode
                Model = ($_.Content.ReadAsStringAsync().GetAwaiter().GetResult() | ConvertFrom-Json)
            }
        })
    }
    finally {
        $client.Dispose()
    }
}

try {
    Invoke-TaskScenario reset TRN-012
    Invoke-TaskScenario apply TRN-012
    Set-TaskFaultProfile none | Out-Null
    $body = New-OrderBody 1

    $sequentialKey = 'trn012-sequential'
    $first = Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -Headers @{ 'Idempotency-Key' = $sequentialKey } -ExpectedStatus 201
    $second = Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -Headers @{ 'Idempotency-Key' = $sequentialKey } -ExpectedStatus 201
    $firstOrder = $first.Body | ConvertFrom-Json
    $secondOrder = $second.Body | ConvertFrom-Json
    if ($firstOrder.id -ne $secondOrder.id) {
        throw "Sequential replay created orders $($firstOrder.id) and $($secondOrder.id)."
    }
    Invoke-TaskApiRequest -Path "/api/orders/$($firstOrder.id)" -ExpectedStatus 200 | Out-Null
    Invoke-TaskSqlFile -TaskId TRN-012 -File assert-single-order.sql -Variables @{ IdempotencyKey = $sequentialKey }

    $conflictKey = 'trn012-conflict'
    Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body (New-OrderBody 1) -Headers @{ 'Idempotency-Key' = $conflictKey } -ExpectedStatus 201 | Out-Null
    Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body (New-OrderBody 2) -Headers @{ 'Idempotency-Key' = $conflictKey } -ExpectedStatus 409 | Out-Null
    Invoke-TaskSqlFile -TaskId TRN-012 -File assert-single-order.sql -Variables @{ IdempotencyKey = $conflictKey }

    $parallelKey = 'trn012-parallel'
    $parallel = Invoke-ConcurrentOrders $parallelKey $body
    if (@($parallel.Status | Where-Object { $_ -ne 201 }).Count -ne 0 -or
        @($parallel.Model.id | Sort-Object -Unique).Count -ne 1) {
        throw 'Concurrent requests did not converge on one replayed HTTP 201 result.'
    }
    Invoke-TaskSqlFile -TaskId TRN-012 -File assert-single-order.sql -Variables @{ IdempotencyKey = $parallelKey }

    $timeoutKey = 'trn012-timeout'
    Set-TaskFaultProfile order-response-timeout | Out-Null
    $lostResponse = Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -Headers @{ 'Idempotency-Key' = $timeoutKey } -MaximumSeconds 1 -AllowCurlFailure
    if ($lostResponse.CurlExitCode -eq 0) {
        throw 'Expected the controlled first response to time out at the client.'
    }
    Start-Sleep -Seconds 3
    Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -Headers @{ 'Idempotency-Key' = $timeoutKey } -ExpectedStatus 201 | Out-Null
    Invoke-TaskSqlFile -TaskId TRN-012 -File assert-single-order.sql -Variables @{ IdempotencyKey = $timeoutKey }

    Set-TaskFaultProfile none | Out-Null
    Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -ExpectedStatus 201 | Out-Null
    Invoke-TaskApiRequest -Path '/api/orders' -Method POST -Body $body -ExpectedStatus 201 | Out-Null
    Write-Host 'TRN-012 visible verification passed.'
}
finally {
    Set-TaskFaultProfile none | Out-Null
}
