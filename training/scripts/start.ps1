[CmdletBinding()]
param()

. (Join-Path $PSScriptRoot '_common.ps1')
Import-TrainingEnvironment

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("commerce-lab-start-" + [Guid]::NewGuid().ToString('N'))
$pluginsFile = Join-Path $temporaryRoot 'plugins.json'
$preservePluginRegistry = $false
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

try {
    $copyArguments = @(Get-ComposeArguments) + @('cp', 'app:/app/App_Data/plugins.json', $pluginsFile)
    & docker @copyArguments *> $null
    $preservePluginRegistry = $LASTEXITCODE -eq 0

    Invoke-DockerCompose -Arguments @('--profile', 'core', 'up', '--detach', '--build')

    if ($preservePluginRegistry) {
        Invoke-DockerCompose -Arguments @('cp', $pluginsFile, 'app:/app/App_Data/plugins.json')
        Invoke-DockerCompose -Arguments @('restart', 'app')
    }
}
finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}
