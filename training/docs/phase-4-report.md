# Phase 4 completion report

## Implemented

Phase 4 adds the three student-visible pilot baselines only:

- TRN-001: controlled transient and permanent database-read fault profiles, a deterministic scenario, ticket, reproduction, visible acceptance test, and evidence requirements.
- TRN-003: a deterministic multi-source product-details scenario, a contract-first feature ticket, reproduction of the absent route, visible HTTP/nullable/contract checks, and evidence requirements.
- TRN-012: a controlled lost-response profile, persisted scenario table, deterministic cleanup/restock, sequential/parallel/timeout reproduction, visible concurrency and payload-conflict checks, and evidence requirements.

The CI workflow now validates all three baselines three times and confirms that each visible test fails at its intended acceptance boundary. The task framework continues to reject mentor-only artifacts in the student tree.

## Student repository files

Added:

- `src/Plugins/Nop.Plugin.Training.Api/Infrastructure/TrainingDatabaseExceptions.cs`
- `training/db/scenarios/TRN-001/*`
- `training/db/scenarios/TRN-003/*`
- `training/db/scenarios/TRN-012/*`
- `training/scripts/_task-common.ps1`
- `training/scripts/verify-pilot-baselines.ps1`
- `training/tasks/TRN-001/*`
- `training/tasks/TRN-003/*`
- `training/tasks/TRN-012/*`
- `training/docs/phase-4-report.md`

Changed:

- `.github/workflows/training.yml`
- the Training API fault, product, and order controllers, contracts, fault state, and focused infrastructure tests
- `training/spec/openapi.yaml` and its generated bundle
- `training/scripts/verify-api.ps1`
- `training/README.md`
- `training/docs/task-catalog.md`

## Verification performed

- Training API Release build: passed with 0 warnings and 0 errors.
- Focused task-framework and Training API infrastructure tests: 21 passed, 0 failed, 0 skipped.
- PowerShell parser validation: all training scripts parsed successfully.
- Task manifests, template, CI YAML, student/mentor separation, branch guard, and secret scan: passed.
- OpenAPI lint, bundle, generated drift, and compatibility: passed; SHA-256 `6D3017F8B1390651DCEBD9E42567B025F2D6D1C62047BB55FDEC528DDC7B28CD`.
- Student baseline Docker image and Compose services: app, SQL Server, and Redis healthy.
- `verify-pilot-baselines.ps1`: every pilot reproduced three consecutive times; every visible suite failed for the declared defect; final cleanup succeeded.
- TRN-001 baseline: HTTP 500 on the controlled transient read in all three runs.
- TRN-003 baseline: existing collection HTTP 200 and missing details route HTTP 404 in all three runs; SQL confirmed product 1, null GTIN, and one category mapping.
- TRN-012 baseline: sequential, parallel, and lost-response retry paths each persisted two orders in all three runs; SQL assertions passed.
- External mentor reference cycle: all three visible suites and all three hidden suites passed against the reference build; the runtime contract and persisted-state edge checks also passed.
- Platform verification: HTTP 200, Redis PONG, and persisted synthetic SQL state passed.
- API verification: authenticated reads 200; order create 201; payment and cancellation 200; runtime OpenAPI 200 and byte-equivalent to source; SQL confirmed one order item for the created smoke order.
- Final Phase 4 cleanup SQL: zero active pilot scenario rows, zero `trn012-*` idempotency rows, and zero tagged pilot orders.
- `git diff --check`: passed.

The package vulnerability audit emitted `NU1900` when the sandbox could not reach the NuGet vulnerability service. Restore, build, and tests themselves passed.

## Separation and limitations

Mentor notes, three hint levels, review checklists, hidden tests, reference sources, and solution patches were created and executed in a separate local mentor repository. They are absent from the student Git tree and no mentor remote or solution ref was added to it.

The separate local mentor repository is protected only by local filesystem access; an organization deployment still needs an access-controlled mentor remote and CI secret boundary. No task baseline or solution branch was materialized because this phase was explicitly executed without commits. The manifests reserve `task/TRN-001-baseline`, `task/TRN-003-baseline`, and `task/TRN-012-baseline`; the repository owner can create those checkpoint branches from the accepted commit.

No commit, push, pull request, published branch, or remote workflow was created. Phase 5 has not started.
