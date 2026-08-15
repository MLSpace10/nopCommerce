# Upstream audit

Audit date: 2026-08-15.

## Source baseline

- Canonical upstream: https://github.com/nopSolutions/nopCommerce.git
- Training fork remote: https://github.com/MLSpace10/nopCommerce.git
- Branch observed: `develop`
- Pinned source commit: `64bdf2ff08c8b39e65717bcf974fb43dc2ef68f2`
- Commit subject: `Merge branch 'issue-4279-product-3d-models' into develop`
- License: nopCommerce Public License 4.0, based on GNU AGPLv3 with an additional visible "powered by nopCommerce" attribution requirement on every UI screen. The lab must preserve that attribution and remain suitable for source disclosure under the NPL.

The repository README currently says .NET 9, but the executable sources are authoritative for this baseline: `global.json` pins SDK `10.0.100` with `latestFeature` roll-forward, `src/Directory.Build.props` targets `net10.0`, and the Dockerfile uses .NET 10 SDK/runtime images. The installed local SDK `10.0.302` satisfies the roll-forward policy.

## Database and local runtime decision

nopCommerce contains providers and migration integration for SQL Server, MySQL 8, and PostgreSQL 15. Phase 1 uses SQL Server 2022 Developer because the target curriculum explicitly includes SQL Server-specific query plans, transaction/isolation work, and advanced SQL exercises. PostgreSQL remains a later portability gate, not the primary baseline.

Core runtime:

- SQL Server 2022 Developer with a project-scoped named volume;
- Redis 7 for cross-instance cache scenarios;
- nopCommerce application built from this commit;
- one-shot initializer using the standard nopCommerce installation HTTP flow;
- idempotent training metadata seed and SQL assertions.

Docker Desktop 4.86.0, Engine 29.7.2, and Compose 5.3.1 were detected. No containers or databases were mutated during Phase 0.

## Build and test commands

```powershell
dotnet build ./src/NopCommerce.sln --configuration Release
dotnet test ./src/Tests/Nop.Tests/Nop.Tests.csproj --configuration Release --no-build
```

NopCommerce currently has one NUnit test project, partitioned into Core, Data, Services, and Web test directories. `BaseNopTest` installs a SQLite-backed test database. These tests are valuable but are not a substitute for SQL Server integration, HTTP, or persisted-state evidence in training tasks.

## Run modes

- Existing upstream Dockerfiles and compose files provide basic SQL Server, PostgreSQL, and MySQL launch examples but use mutable image tags, hard-coded credentials, no readiness chain, and no deterministic reset/seed verification.
- The lab entry point is `./training/scripts/bootstrap.ps1` using `training/compose.yml`.
- Direct source execution remains possible with `dotnet run --project ./src/Presentation/Nop.Web/Nop.Web.csproj`, followed by standard nopCommerce installation.

## Architecture and extension points

- HTTP: ASP.NET Core controllers under `Nop.Web` and plugin controllers derived from nopCommerce controller bases.
- Services: interfaces and partial/virtual implementations in `Nop.Services`; existing services should remain the business boundary.
- Persistence: `IRepository<TEntity>` / `EntityRepository<TEntity>` over Linq2DB, with FluentMigrator for schema evolution.
- Caching: `IStaticCacheManager`, short-term cache, Redis-backed distributed/synchronized-memory implementations, and entity event invalidation.
- Events: `IEventPublisher` and typed consumers discovered through nopCommerce startup conventions.
- Plugins: `BasePlugin`, `IPlugin`, `INopStartup`, plugin controllers, and plugin migrations. A separate `Nop.Plugin.Training.Api` is the preferred Phase 2 boundary.
- Tests: NUnit, the existing `BaseNopTest`, service test bases, repository tests, and web tests. External SQL Server/Redis tests must be separate and explicitly classified.

## Historical bug candidates

Candidates are recorded in `historical-bug-candidates.md`. Phase 0 verifies issue/fix provenance from public GitHub and local Git history; it does not claim local reproduction yet. Reproduction is a separate quality gate before any candidate becomes a student task.

## Known limitations and risks

- NPL attribution and source-disclosure obligations require legal awareness before distributing the lab outside the intended open-source setting.
- The upstream README lags the actual .NET 10 baseline.
- The standard installation endpoint is UI-oriented and uses antiforgery; the lab initializer deliberately drives that public flow instead of duplicating installation internals.
- The built-in sample data is used only to bootstrap a representative nopCommerce graph. Training-specific scenarios must add explicit versioned apply/reset/verify scripts.
- Docker images need to be pulled on first bootstrap; this requires internet access and can take several minutes.
- Mentor solutions and hidden tests require a separate mentor-only repository or remote. They must never be placed in a student-accessible branch.

