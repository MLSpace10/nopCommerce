# Debugging the lab

- Platform status: `./training/scripts/health.ps1`.
- Core HTTP, SQL, and Redis assertions: `./training/scripts/verify-platform.ps1`.
- API and persisted order flow: `./training/scripts/verify-api.ps1`.
- Contract lint/drift/compatibility: `./training/scripts/verify-contract.ps1`.
- Task metadata and separation: `./training/scripts/verify-task-framework.ps1`.
- Compose logs: `docker compose --project-name commerce-engineering-lab --env-file training/.env --file training/compose.yml logs --tail 200 app`.

For a task, reset its versioned scenario before reproducing. Do not repair data manually; update the scenario only when its declared baseline is wrong. A missing scenario file, manifest mismatch, mentor artifact, suspected secret, or `solution/*` checkout is a framework failure, not an application defect.

Use only the explicit Compose project `commerce-engineering-lab` and database `CommerceEngineeringLab`. Never adapt destructive commands to an unknown server or database.
