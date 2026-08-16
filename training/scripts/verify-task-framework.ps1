[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot '_common.ps1')
$trainingRoot = Get-TrainingRoot
$repositoryRoot = Split-Path -Parent $trainingRoot
$toolProject = Join-Path $repositoryRoot 'src/Tools/Nop.Training.TaskTool/Nop.Training.TaskTool.csproj'
$templateManifest = Join-Path $trainingRoot 'task-framework/templates/student-task/manifest.yaml'
$schemaPath = Join-Path $trainingRoot 'task-framework/manifest.schema.json'
$workflowPath = Join-Path $repositoryRoot '.github/workflows/training.yml'

Get-Content -LiteralPath $schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null

& dotnet run --project $toolProject --configuration Release -- validate
if ($LASTEXITCODE -ne 0) {
    throw 'Repository task manifest validation failed.'
}

& dotnet run --project $toolProject --configuration Release -- validate-manifest $templateManifest
if ($LASTEXITCODE -ne 0) {
    throw 'Student task template manifest validation failed.'
}

& dotnet run --project $toolProject --configuration Release -- validate-yaml $workflowPath
if ($LASTEXITCODE -ne 0) {
    throw 'Training CI workflow YAML syntax validation failed.'
}

$currentBranch = (& git -C $repositoryRoot branch --show-current | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to determine current Git branch.'
}
if ($currentBranch -like 'solution/*') {
    throw "Mentor solution branch '$currentBranch' must not be used as a student/platform checkpoint."
}

$repositoryFiles = @(& git -C $repositoryRoot ls-files --cached --others --exclude-standard)
if ($LASTEXITCODE -ne 0) {
    throw 'Unable to enumerate repository files for separation checks.'
}

$mentorLeakPattern = '(^|/)(mentor-notes\.md|solution\.patch|hidden-tests|review-checklist\.md|hints)(/|$)'
$mentorLeaks = @($repositoryFiles | Where-Object {
    $_ -like 'training/tasks/*' -and $_ -match $mentorLeakPattern
})
if ($mentorLeaks.Count -gt 0) {
    throw "Mentor-only artifacts found in student task tree: $($mentorLeaks -join ', ')"
}

$secretPattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{30,}'
$secretLeaks = @()
foreach ($relativePath in $repositoryFiles) {
    if ($relativePath -notmatch '\.(cs|csproj|json|md|ps1|sql|ya?ml|props|targets|sln)$') {
        continue
    }
    $fullPath = Join-Path $repositoryRoot $relativePath
    if ((Test-Path -LiteralPath $fullPath -PathType Leaf) -and
        (Select-String -LiteralPath $fullPath -Pattern $secretPattern -Quiet)) {
        $secretLeaks += $relativePath
    }
}
if ($secretLeaks.Count -gt 0) {
    throw "Potential secrets found: $($secretLeaks -join ', ')"
}

Write-Host 'Task manifests, template, student/mentor separation, branch guard, and secret scan passed.'
