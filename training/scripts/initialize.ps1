[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BaseUrl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_initialize-result.ps1')

$database = [Environment]::GetEnvironmentVariable('TRAINING_DATABASE')
$saPassword = [Environment]::GetEnvironmentVariable('MSSQL_SA_PASSWORD')
$adminEmail = [Environment]::GetEnvironmentVariable('TRAINING_ADMIN_EMAIL')
$adminPassword = [Environment]::GetEnvironmentVariable('TRAINING_ADMIN_PASSWORD')

$session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
$installPage = Invoke-WebRequest -Uri "$BaseUrl/install" -WebSession $session -MaximumRedirection 5 -TimeoutSec 30

if ($installPage.BaseResponse.RequestMessage.RequestUri.AbsolutePath -notlike '/install*') {
    Write-Host 'nopCommerce is already installed; initializer is idempotent.'
    exit 0
}

$tokenMatch = [regex]::Match($installPage.Content, 'name="__RequestVerificationToken" type="hidden" value="([^"]+)"')
if (-not $tokenMatch.Success) {
    throw 'Could not find the nopCommerce installation antiforgery token.'
}

$connectionString = "Server=database,1433;Database=$database;User Id=sa;Password=$saPassword;TrustServerCertificate=True;Encrypt=False"
$form = @{
    __RequestVerificationToken = $tokenMatch.Groups[1].Value
    AdminEmail = $adminEmail
    AdminPassword = $adminPassword
    ConfirmPassword = $adminPassword
    DataProvider = '1'
    ConnectionStringRaw = 'true'
    ConnectionString = $connectionString
    InstallSampleData = 'true'
    SubscribeNewsletters = 'false'
    InstallRegionalResources = 'false'
    CreateDatabaseIfNotExists = 'true'
}

$result = Invoke-WebRequest -Uri "$BaseUrl/install" -Method Post -Body $form -WebSession $session -TimeoutSec 240
if (-not (Test-NopInstallationResponseSuccessful -Html $result.Content)) {
    $errorText = Get-NopInstallationErrorText -Html $result.Content -SensitiveValues @(
        $connectionString,
        $saPassword,
        $adminPassword,
        [Environment]::GetEnvironmentVariable('TRAINING_API_KEY')
    )
    throw "nopCommerce installation failed: $errorText"
}

Invoke-WebRequest -Uri "$BaseUrl/install/restartapplication" -WebSession $session -TimeoutSec 30 | Out-Null
Write-Host 'nopCommerce schema and built-in synthetic sample data installed.'
