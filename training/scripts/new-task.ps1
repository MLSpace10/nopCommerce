[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^TRN-[0-9]{3}$')]
    [string]$Id,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Title,

    [Parameter(Mandatory)]
    [ValidateSet('bug', 'feature', 'investigation', 'database-change', 'integration', 'operational-audit')]
    [string]$Type,

    [ValidateSet('beginner', 'intermediate', 'advanced')]
    [string]$Difficulty = 'intermediate',

    [ValidateRange(15, 960)]
    [int]$EstimatedMinutes = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_common.ps1')
$trainingRoot = Get-TrainingRoot
$studentTemplate = Join-Path $trainingRoot 'task-framework/templates/student-task'
$scenarioTemplate = Join-Path $trainingRoot 'task-framework/templates/scenario'
$taskDirectory = Join-Path $trainingRoot "tasks/$Id"
$scenarioDirectory = Join-Path $trainingRoot "db/scenarios/$Id"

if (Test-Path -LiteralPath $taskDirectory) {
    throw "Task directory already exists: $taskDirectory"
}
if (Test-Path -LiteralPath $scenarioDirectory) {
    throw "Scenario directory already exists: $scenarioDirectory"
}

if (-not $PSCmdlet.ShouldProcess($Id, 'Create student task and deterministic SQL scenario skeletons')) {
    return
}

Copy-Item -LiteralPath $studentTemplate -Destination $taskDirectory -Recurse
Copy-Item -LiteralPath $scenarioTemplate -Destination $scenarioDirectory -Recurse

$manifestPath = Join-Path $taskDirectory 'manifest.yaml'
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8
$yamlTitle = $Title | ConvertTo-Json -Compress
$manifest = $manifest.Replace('TRN-000', $Id)
$manifest = $manifest.Replace('title: Replace with a student-facing title', "title: $yamlTitle")
$manifest = $manifest.Replace('type: bug', "type: $Type")
$manifest = $manifest.Replace('difficulty: intermediate', "difficulty: $Difficulty")
$manifest = $manifest.Replace('estimatedMinutes: 90', "estimatedMinutes: $EstimatedMinutes")
[IO.File]::WriteAllText($manifestPath, $manifest, [Text.UTF8Encoding]::new($false))

$ticketPath = Join-Path $taskDirectory 'student-ticket.md'
$ticket = (Get-Content -LiteralPath $ticketPath -Raw -Encoding UTF8)
$ticket = $ticket.Replace('# Replace with task title', "# $Title").Replace('Type: bug', "Type: $Type")
[IO.File]::WriteAllText($ticketPath, $ticket, [Text.UTF8Encoding]::new($false))

Write-Host "Created $Id skeleton. Replace every placeholder before creating its baseline branch."
