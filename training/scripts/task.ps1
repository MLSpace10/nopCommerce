[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('list', 'validate', 'reproduce', 'verify', 'reset')]
    [string]$Operation,

    [Parameter(Position = 1)]
    [ValidatePattern('^TRN-[0-9]{3}$')]
    [string]$TaskId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_common.ps1')
$trainingRoot = Get-TrainingRoot
$repositoryRoot = Split-Path -Parent $trainingRoot
$toolProject = Join-Path $repositoryRoot 'src/Tools/Nop.Training.TaskTool/Nop.Training.TaskTool.csproj'

function Invoke-TaskTool {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $dotnetArguments = @('run', '--project', $toolProject, '--configuration', 'Release', '--') + $Arguments
    & dotnet @dotnetArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Task manifest validation failed with exit code $LASTEXITCODE."
    }
}

if ($Operation -eq 'list') {
    Invoke-TaskTool -Arguments @('list')
    exit 0
}

if ($Operation -eq 'validate' -and [string]::IsNullOrWhiteSpace($TaskId)) {
    Invoke-TaskTool -Arguments @('validate')
    exit 0
}

if ([string]::IsNullOrWhiteSpace($TaskId)) {
    throw "TaskId is required for operation '$Operation'."
}

$taskDirectory = Join-Path $trainingRoot "tasks/$TaskId"
$manifestPath = Join-Path $taskDirectory 'manifest.yaml'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Task does not exist: $TaskId"
}

Invoke-TaskTool -Arguments @('validate')

switch ($Operation) {
    'validate' { return }
    'reproduce' { & (Join-Path $taskDirectory 'reproduce.ps1') }
    'verify' { & (Join-Path $taskDirectory 'visible-tests/verify.ps1') }
    'reset' { & (Join-Path $PSScriptRoot 'scenario.ps1') reset $TaskId }
}

if ($LASTEXITCODE -ne 0) {
    throw "Task operation '$Operation' failed with exit code $LASTEXITCODE."
}
