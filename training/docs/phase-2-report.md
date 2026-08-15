# Phase 2 completion report

Date: 2026-08-15

## Implemented

- Added the open-source `Nop.Plugin.Training.Api` plugin without changing nopCommerce core business services.
- Added authenticated REST operations for customers, products, inventory, orders, payments, the Phase 1 outbox, development-only fault profile control, health, and the runtime OpenAPI document.
- Used existing nopCommerce customer, catalog, order, order-processing, and data-provider services. Order smoke verification checks the resulting `Order` and `OrderItem` rows in `CommerceEngineeringLab`.
- Added `training/spec/openapi.yaml` as the source contract and serve its exact embedded bytes from `/api/openapi.yaml`.
- Added a pinned `redocly/cli:2.32.2` contract build with lint, bundle generation, generated-file drift detection, and a checked-in backward-compatibility baseline.
- Added constant-time API-key authentication through the development-only `TRAINING_API_KEY` setting. Health and the OpenAPI source remain unauthenticated.
- Added focused middleware/fault-state tests and real curl smoke coverage for every Phase 2 route group.
- Extended Compose with persistent app data and a compatible Phase 1 plugin-registry carry-forward. The explicit project and database safety boundaries remain `commerce-engineering-lab` and `CommerceEngineeringLab`.

No generated client was added: Phase 2 has no in-repository client consumer, so a pinned bundled contract plus handwritten server DTOs avoids unused generated code while retaining drift and compatibility checks.

## Files

Added:

- `src/Plugins/Nop.Plugin.Training.Api/**`
- `src/Tests/Nop.Tests/Nop.Plugin.Training.Api.Tests/TrainingApiInfrastructureTests.cs`
- `training/db/assertions/api.sql`
- `training/scripts/install-training-api.ps1`
- `training/scripts/verify-api.ps1`
- `training/scripts/verify-contract.ps1`
- `training/spec/openapi.yaml`
- `training/spec/redocly.yaml`
- `training/spec/compatibility-baseline.json`
- `training/spec/generated/openapi.json`
- `training/docs/phase-2-report.md`

Changed as compatible Phase 2 extensions:

- `Dockerfile`
- `src/NopCommerce.sln`
- `src/Tests/Nop.Tests/Nop.Tests.csproj`
- `training/.env.example`
- `training/.gitignore`
- `training/README.md`
- `training/compose.yml`
- `training/docs/architecture.md`
- `training/scripts/_common.ps1`
- `training/scripts/bootstrap.ps1`
- `training/scripts/start.ps1`

## Executed verification and actual results

- `dotnet build src/Plugins/Nop.Plugin.Training.Api/Nop.Plugin.Training.Api.csproj --configuration Release --no-restore`: passed, 0 warnings, 0 errors, 10.74 s. Earlier diagnostic attempts exposed and then fixed a standalone output-path issue, restricted NuGet restore, and two missing namespaces.
- `dotnet build src/NopCommerce.sln --configuration Release --no-restore`: passed, 0 warnings, 0 errors, 2 min 10.63 s.
- Docker build through `training/scripts/start.ps1`: passed; solution build inside the Linux image completed in 5 min 47.60 s with 0 errors and 3 existing upstream warnings (`CS0618` twice in upgrade migrations and `CS0108` in the generated VAT service reference).
- `dotnet test src/Tests/Nop.Tests/Nop.Tests.csproj --configuration Release --no-restore --filter FullyQualifiedName~TrainingApiInfrastructureTests`: passed, 8 passed, 0 failed, 0 skipped, 391 ms.
- `training/scripts/verify-contract.ps1`: passed. Redocly lint reported a valid contract with no problems; bundle generation, drift, and compatibility checks passed. SHA-256: `04627639C4C76219986B3736033AA9C9256F5C960D014145D43468B82A25BE1C`.
- `training/scripts/health.ps1`: passed; app returned HTTP 200 and app, SQL Server, and Redis containers were healthy.
- `training/scripts/verify-platform.ps1`: passed; database was `CommerceEngineeringLab`, persisted counts were customers 18, products 47, training audit events 1, integration messages 1, and Redis returned PONG.
- `training/scripts/verify-api.ps1`: passed all real curl checks: public health 200, protected request without a key 401, all authenticated route groups 200/201 as specified, and runtime OpenAPI 200 with a source/runtime hash match. It created order 6, recorded payment, cancelled it, and verified in SQL: status 40, payment status 30, total 1200.0000, one order item.
- Repeated `training/scripts/start.ps1`: passed with cached image layers; subsequent inspection showed 31 installed plugins, exactly one `Training.Api`, no pending installs, and an authenticated products request returned HTTP 200.
- PowerShell parser over all `training/scripts/*.ps1`: passed.
- `docker compose --project-name commerce-engineering-lab --env-file training/.env --file training/compose.yml config --quiet`: passed. Docker emitted only a local config-file access warning in the restricted diagnostic shell.
- `git diff --check`: passed; Git emitted only line-ending conversion notices.

Two plugin-registration diagnostic attempts failed before HTTP verification because the first script version serialized the nopCommerce install queue as ordinary named JSON fields. nopCommerce uses a `ValueTuple` and requires `Item1`/`Item2`; the script was corrected, the accepted 30-plugin Phase 1 registry was restored, and the successful repeated-start check above verifies the final behavior.

## Assumptions and incomplete items

- The API is a local training boundary and `ASPNETCORE_ENVIRONMENT=Development`; the API key is not a production authentication mechanism.
- The deterministic Phase 1 installation provides store, language, customer billing address, products, USD pricing, and the manual payment plugin used by the order smoke flow.
- There are no blockers or incomplete Phase 2 verification items.
- Phase 3 and later phases have not started. No pilot task baseline, task branch, pull request, commit, push, or publication was created.
