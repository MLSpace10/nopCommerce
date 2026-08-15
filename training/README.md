# Commerce Engineering Lab

1. Run `./training/scripts/bootstrap.ps1`.
2. Check out the task baseline branch selected by the mentor.
3. Run the task's `reproduce.ps1` and capture HTTP and database evidence.
4. Implement the smallest compatible fix and run the task verification command.

This directory contains a local, synthetic, production-like backend lab based on the open-source nopCommerce codebase. Phase 1 provides the core SQL Server, Redis, nopCommerce, installation/seed, health, reset, and smoke-test workflow. Training API and task baselines are added in later phases only after this platform is repeatable.

## Quick commands

```powershell
./training/scripts/bootstrap.ps1
./training/scripts/health.ps1
./training/scripts/verify-platform.ps1
./training/scripts/stop.ps1
```

`reset.ps1` is intentionally destructive only for the explicit Compose project `commerce-engineering-lab`; it removes that project's containers and named volumes and recreates the local synthetic environment.

Local configuration is copied from `.env.example` to ignored `.env`. All example credentials are development-only placeholders. Replace them locally if the machine is shared.

## Current scope

- Phase 0: audit and ADRs are recorded under `training/docs`.
- Phase 1: implemented by `training/compose.yml` and `training/scripts`.
- Phases 2–4: not yet claimed complete; no training API or pilot-task baseline is exposed prematurely.

