# Phase 0 and Phase 1 report

Report date: 2026-08-15.

## Ready

- Phase 0 audit pins commit `64bdf2ff08c8b39e65717bcf974fb43dc2ef68f2`, records licensing and runtime constraints, historical candidates, architecture, and three ADRs.
- Phase 1 provides the `commerce-engineering-lab` Compose project with SQL Server 2022 Developer, Redis 7, nopCommerce, an HTTP-driven installer, deterministic synthetic seed, health checks, persisted-state assertions, stop, and guarded reset tooling.
- Local secrets and generated nopCommerce app settings are ignored.

## Executed evidence

```text
dotnet build src/NopCommerce.sln --configuration Release --no-restore
  0 errors; 3 pre-existing upstream warnings

training/scripts/bootstrap.ps1
  HTTP 200: http://localhost:8080/
  database: CommerceEngineeringLab
  customers: 13
  products: 47
  training audit events: 1
  training integration messages: 1
  Redis: PONG
```

At the end of verification, `app`, `database`, and `redis` were healthy. The one-shot `initializer` and `seed` containers exited with code 0.

The initial container probe used `/` and was found to create nopCommerce guest customers on every poll. It was replaced with the static `/favicon.ico` probe. A persisted-state check over 20 seconds confirmed a stable customer count (`63` before and after); the dynamic homepage remains part of explicit smoke verification only.

## Reset verification

After explicit approval, the destructive reset-cycle was executed. The first attempt exposed a profile-handling defect: `down` without `--profile core` did not remove profiled services. The script was corrected and the invalid attempt was not counted.

The repeated cycle visibly removed every `commerce-engineering-lab` container, both named volumes, and the project network, then recreated them. Verification against the clean database returned HTTP 200, 11 customers, 47 products, one training audit event, one training integration message, and Redis `PONG`.

The reset script refuses any Compose identity other than `commerce-engineering-lab`; all shared script entry points also refuse any database name other than `CommerceEngineeringLab`.

Phase 2 has not started. No training API or task baselines are claimed complete.
