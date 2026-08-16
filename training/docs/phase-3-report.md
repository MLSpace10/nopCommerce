# Phase 3 completion report

Date: 2026-08-16

Checkpoint parent: `878b111d85` (`Add training API and contract verification`)

## Implemented

- Added a versioned task manifest contract, a student-task template, deterministic scenario templates, and strict `TRN-###` identity/branch/command conventions.
- Added the isolated .NET 10 `Nop.Training.TaskTool` with pinned `YamlDotNet 18.1.0` for YAML parsing, repository validation, task listing, CI YAML syntax checking, and student/mentor separation enforcement.
- Added guarded PowerShell entrypoints for task list/validation/reproduction/visible verification/reset, scenario apply/reset/verify, skeleton generation, and complete framework verification.
- Added validation for required student artifacts, deterministic SQL scenario operations, allowed task types/difficulties, compatibility and learning metadata, duplicate collections, opaque hidden-verification commands, path traversal, common secret forms, solution-branch use, and mentor-only artifact leakage.
- Added eight task-manifest validator tests covering valid and invalid manifests, nested repository discovery, student/mentor separation, hidden command isolation, missing visible tests/scenario files, unknown YAML properties, null collections, and duplicates.
- Added the 100-point scoring rubric and student, mentor, task-authoring, debugging, catalog, security/data, and upstream-update documentation.
- Added a training CI workflow for restore/build, Phase 2 and Phase 3 focused tests, task-framework validation, Docker bootstrap, HTTP/SQL/Redis/OpenAPI/API verification, an empty-database reset cycle, persisted-state checks, separation/secret checks, and cleanup.
- Made the accepted Phase 2 curl smoke script select `curl.exe` on Windows or `curl` on Linux so the same real HTTP checks can run in CI.

No task baseline, task defect, pilot seed, mentor solution, hidden test, or `solution/*` branch was created. Those belong to Phase 4.

## Files added

- `.github/workflows/training.yml`
- `src/Tools/Nop.Training.TaskTool/Nop.Training.TaskTool.csproj`
- `src/Tools/Nop.Training.TaskTool/Program.cs`
- `src/Tools/Nop.Training.TaskTool/TaskManifest.cs`
- `src/Tools/Nop.Training.TaskTool/TaskManifestValidator.cs`
- `src/Tests/Nop.Tests/Nop.Training.TaskTool.Tests/TaskManifestValidatorTests.cs`
- `training/task-framework/manifest.schema.json`
- `training/task-framework/templates/student-task/**`
- `training/task-framework/templates/scenario/**`
- `training/tasks/README.md`
- `training/scripts/new-task.ps1`
- `training/scripts/scenario.ps1`
- `training/scripts/task.ps1`
- `training/scripts/verify-task-framework.ps1`
- `training/docs/adding-a-task.md`
- `training/docs/debugging.md`
- `training/docs/mentor-workflow.md`
- `training/docs/phase-3-report.md`
- `training/docs/scoring-rubric.md`
- `training/docs/security-and-data.md`
- `training/docs/student-workflow.md`
- `training/docs/task-catalog.md`
- `training/docs/upstream-update.md`

## Files changed

- `src/NopCommerce.sln`
- `src/Tests/Nop.Tests/Nop.Tests.csproj`
- `training/README.md`
- `training/db/scenarios/README.md`
- `training/docs/architecture.md`
- `training/scripts/bootstrap.ps1`
- `training/scripts/verify-api.ps1`

## Commands executed and actual results

- `dotnet restore src/Tools/Nop.Training.TaskTool/Nop.Training.TaskTool.csproj`: passed after network escalation; restored pinned `YamlDotNet 18.1.0`.
- `dotnet build src/Tools/Nop.Training.TaskTool/Nop.Training.TaskTool.csproj --configuration Release --no-restore`: passed, 0 warnings, 0 errors. The final focused build took 7.54 seconds.
- `dotnet restore src/Tests/Nop.Tests/Nop.Tests.csproj`: passed; eight projects were current/restored.
- `dotnet restore src/NopCommerce.sln`: passed; all projects were current.
- `dotnet build src/NopCommerce.sln --configuration Release --no-restore --maxcpucount:1`: passed twice. The final current-tree build completed with 0 warnings, 0 errors in 1 minute 52.97 seconds (the earlier clean graph build took 3 minutes 22.26 seconds).
- `dotnet test src/Tests/Nop.Tests/Nop.Tests.csproj --configuration Release --no-restore --filter 'FullyQualifiedName~TaskManifestValidatorTests|FullyQualifiedName~TrainingApiInfrastructureTests' --maxcpucount:1`: passed, 16 passed, 0 failed, 0 skipped, 931 ms.
- PowerShell parser over every `training/scripts/*.ps1`: passed.
- JSON parsing of `training/task-framework/manifest.schema.json`: passed.
- `docker compose --project-name commerce-engineering-lab --env-file training/.env --file training/compose.yml config --quiet`: passed.
- `training/scripts/task.ps1 list`: passed and reported no task baselines.
- `training/scripts/task.ps1 validate`: passed.
- `training/scripts/new-task.ps1 ... -WhatIf`: passed without creating a task.
- `training/scripts/verify-task-framework.ps1`: passed manifest, template, CI YAML syntax, student/mentor separation, branch, and secret checks.
- Negative scenario checks: missing `TRN-999` operation was rejected before Docker/SQL; invalid `../bad` task ID was rejected by parameter validation.
- `training/scripts/start.ps1`: Docker image build and compatible restart passed. The Linux solution build took 7 minutes 58.13 seconds with 0 errors and the same three accepted upstream warnings (`CS0618` twice in the 4.70 upgrade migration and `CS0108` in the generated VAT service reference).
- `training/scripts/health.ps1`: passed; app, SQL Server, and Redis containers were healthy and application HTTP returned 200.
- `training/scripts/verify-platform.ps1`: passed. Database `CommerceEngineeringLab` contained 40 customers, 47 products, one training audit event, and one integration message; Redis returned PONG.
- `training/scripts/verify-contract.ps1`: passed Redocly lint, bundle, generated drift, and compatibility checks. Contract SHA-256 remained `04627639C4C76219986B3736033AA9C9256F5C960D014145D43468B82A25BE1C`.
- `training/scripts/verify-api.ps1`: passed all real curl checks. Public health returned 200, an unauthenticated protected request returned 401, authenticated customer/product/inventory/order/payment/outbox/fault operations returned their expected 200/201 statuses, and runtime OpenAPI returned 200 with a source hash match.
- Persisted database assertion for created order 1001 passed: order status 40, payment status 30, total 1200.0000, one order item.
- `git diff --check`: passed during implementation; final diff and untracked whitespace checks are recorded in the handoff response.

## Errors found and fixed

- Initial NuGet restore failed with `NU1301` because sandbox networking redirected NuGet to `127.0.0.1:9`. The same scoped restore succeeded with approved network access.
- The first focused test build spawned 170 parallel MSBuild/dotnet workers and stopped producing progress. Only processes started by that test session were terminated; rerunning with `--maxcpucount:1` completed successfully. Subsequent full build and tests used the same deterministic limit.
- The first `task.ps1 list` dry run executed the default validator because arguments after `dotnet run --` were splatted incorrectly. The wrapper now builds and passes one explicit argv array; `list` and `validate` were rerun successfully.
- Review found that explicit YAML `null` collections could bypass non-null C# defaults and cause validator exceptions. Null-safe checks, duplicate checks, and a regression test were added; the final 16-test run passed.
- The first Docker check failed before build because Docker Desktop was stopped. The installed Docker Desktop 4.86.0 was started, engine readiness was confirmed, and the full Docker/HTTP/SQL/Redis verification then passed.

## Assumptions, blockers, and incomplete items

- The student and mentor repositories are separate security boundaries. This student repository validates that mentor-only files are absent; creation and execution of actual mentor hidden tests remains Phase 4 work in the mentor repository.
- Phase 3 introduces no database schema migration, so no previous-training-schema migration is applicable. CI verifies bootstrap/reset from an empty `CommerceEngineeringLab`; upgrade behavior for future training schema versions must be added with the first such migration.
- The repository secret scan is deliberately a focused guardrail for common high-confidence key forms; organization-level scanning remains an external defense.
- GitHub Actions was syntax-validated and its constituent commands were run locally, but the hosted workflow itself was not dispatched because publishing or remote workflow execution was not authorized.
- There are no blocking or incomplete Phase 3 implementation items.
- No commit, push, pull request, branch publication, or upstream interaction was performed.
- Phase 4 has not started.
