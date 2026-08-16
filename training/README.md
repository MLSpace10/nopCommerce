# Commerce Engineering Lab

1. Run `./training/scripts/bootstrap.ps1`.
2. Check out the task baseline branch selected by the mentor.
3. Run the task's `reproduce.ps1` and capture HTTP and database evidence.
4. Implement the smallest compatible fix and run the task verification command.

This directory contains a local, synthetic, production-like backend lab based on the open-source nopCommerce codebase. Phase 1 provides the core SQL Server, Redis, nopCommerce, installation/seed, health, reset, and smoke-test workflow. Phase 2 adds an authenticated training API plugin and an OpenAPI-first contract workflow without changing nopCommerce core business services.

## Quick commands

```powershell
./training/scripts/bootstrap.ps1
./training/scripts/health.ps1
./training/scripts/verify-platform.ps1
./training/scripts/verify-contract.ps1
./training/scripts/verify-api.ps1
./training/scripts/verify-task-framework.ps1
./training/scripts/task.ps1 list
./training/scripts/stop.ps1
```

The API source contract is `training/spec/openapi.yaml`; the same bytes are served at `http://localhost:8080/api/openapi.yaml`. Except for health and the OpenAPI document, requests require the development-only `X-Training-Api-Key` value from ignored `training/.env`.

The contract check uses the pinned `redocly/cli:2.32.2` image to lint and bundle the specification, detect generated-file drift, and enforce the checked-in compatibility baseline. The API smoke check uses real `curl.exe` requests and verifies the created order and order item in `CommerceEngineeringLab`.

`reset.ps1` is intentionally destructive only for the explicit Compose project `commerce-engineering-lab`; it removes that project's containers and named volumes and recreates the local synthetic environment.

Local configuration is copied from `.env.example` to ignored `.env`. All example credentials are development-only placeholders. Replace them locally if the machine is shared.

## Current scope

- Phase 0: audit and ADRs are recorded under `training/docs`.
- Phase 1: implemented by `training/compose.yml` and `training/scripts`.
- Phase 2: implemented by `Nop.Plugin.Training.Api`, `training/spec`, and the Phase 2 verification scripts.
- Phase 3: implemented by the manifest schema, task tool, guarded scenario runner, student/mentor separation checks, templates, scoring rubric, and workflow documentation.
- Phase 4: not started; no pilot-task baseline, defect seed, hidden test, or mentor solution is included.
