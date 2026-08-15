[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$httpPort = [Environment]::GetEnvironmentVariable('TRAINING_HTTP_PORT')
$apiKey = [Environment]::GetEnvironmentVariable('TRAINING_API_KEY')
if ([string]::IsNullOrWhiteSpace($apiKey)) {
    throw 'TRAINING_API_KEY is required.'
}

$baseUrl = "http://localhost:$httpPort"
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("commerce-lab-api-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

function Invoke-CurlRequest {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Method = 'GET',
        [string]$Body,
        [Parameter(Mandatory)][int]$ExpectedStatus,
        [switch]$Authenticated
    )

    $responseFile = Join-Path $temporaryRoot ([Guid]::NewGuid().ToString('N') + '.body')
    $arguments = @('--silent', '--show-error', '--output', $responseFile, '--write-out', '%{http_code}',
        '--request', $Method)
    if ($Authenticated) {
        $arguments += @('--header', "X-Training-Api-Key: $apiKey")
    }
    if ($Body) {
        $arguments += @('--header', 'Content-Type: application/json', '--data-binary', $Body)
    }
    $arguments += "$baseUrl$Path"

    $status = (& curl.exe @arguments | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "curl failed for $Method $Path with exit code $LASTEXITCODE."
    }
    if ([int]$status -ne $ExpectedStatus) {
        $responseBody = Get-Content -LiteralPath $responseFile -Raw -ErrorAction SilentlyContinue
        throw "Expected HTTP $ExpectedStatus for $Method $Path; received $status. Body: $responseBody"
    }

    Write-Host "$Method $Path -> HTTP $status"
    return Get-Content -LiteralPath $responseFile -Raw
}

try {
    Invoke-CurlRequest -Path '/api/health' -ExpectedStatus 200 | Out-Null
    Invoke-CurlRequest -Path '/api/products?pageSize=5' -ExpectedStatus 401 | Out-Null

    $customers = Invoke-CurlRequest -Path '/api/customers?pageSize=100' -ExpectedStatus 200 -Authenticated | ConvertFrom-Json
    $customer = $customers.items | Where-Object { $null -ne $_.billingAddressId -and $_.active } | Select-Object -First 1
    if ($null -eq $customer) {
        throw 'No active synthetic customer with a billing address was returned.'
    }
    Invoke-CurlRequest -Path "/api/customers/$($customer.id)" -ExpectedStatus 200 -Authenticated | Out-Null

    $products = Invoke-CurlRequest -Path '/api/products?pageSize=20' -ExpectedStatus 200 -Authenticated | ConvertFrom-Json
    $product = $products.items | Where-Object { $_.published -and $_.price -gt 0 } | Select-Object -First 1
    if ($null -eq $product) {
        throw 'No published synthetic product was returned.'
    }
    Invoke-CurlRequest -Path "/api/products/$($product.id)" -ExpectedStatus 200 -Authenticated | Out-Null
    Invoke-CurlRequest -Path "/api/inventory/$($product.id)" -ExpectedStatus 200 -Authenticated | Out-Null

    $createBody = @{ customerId = $customer.id; productId = $product.id; quantity = 1 } | ConvertTo-Json -Compress
    $order = Invoke-CurlRequest -Path '/api/orders' -Method POST -Body $createBody -ExpectedStatus 201 -Authenticated | ConvertFrom-Json
    Invoke-CurlRequest -Path "/api/orders/$($order.id)" -ExpectedStatus 200 -Authenticated | Out-Null

    $paymentBody = @{ orderId = $order.id } | ConvertTo-Json -Compress
    Invoke-CurlRequest -Path '/api/payments' -Method POST -Body $paymentBody -ExpectedStatus 200 -Authenticated | Out-Null
    Invoke-CurlRequest -Path "/api/orders/$($order.id)/cancel" -Method POST -ExpectedStatus 200 -Authenticated | Out-Null
    Invoke-CurlRequest -Path '/api/internal/outbox' -ExpectedStatus 200 -Authenticated | Out-Null
    Invoke-CurlRequest -Path '/api/internal/training/faults/none' -Method POST -ExpectedStatus 200 -Authenticated | Out-Null

    $runtimeSpec = Join-Path $temporaryRoot 'runtime-openapi.yaml'
    $sourceSpec = Join-Path (Get-TrainingRoot) 'spec/openapi.yaml'
    Invoke-CurlRequest -Path '/api/openapi.yaml' -ExpectedStatus 200 | Set-Content -LiteralPath $runtimeSpec -NoNewline -Encoding UTF8
    if ((Get-FileHash $runtimeSpec -Algorithm SHA256).Hash -ne (Get-FileHash $sourceSpec -Algorithm SHA256).Hash) {
        throw 'Runtime OpenAPI differs from training/spec/openapi.yaml.'
    }

    $saPassword = [Environment]::GetEnvironmentVariable('MSSQL_SA_PASSWORD')
    Invoke-DockerCompose -Arguments @(
        'run', '--rm', '--no-deps',
        '-e', "MSSQL_SA_PASSWORD=$saPassword",
        '--entrypoint', '/bin/bash', 'seed', '-c',
        "/opt/mssql-tools18/bin/sqlcmd -C -S database -U sa -P `"`$MSSQL_SA_PASSWORD`" -d CommerceEngineeringLab -v `"OrderId=$($order.id)`" -i /training/db/assertions/api.sql -b"
    )

    Write-Host "Training API curl smoke and persisted order verification passed for order $($order.id)."
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
