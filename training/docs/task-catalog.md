# Task catalog

Phase 4 implements the three required pilots:

- TRN-001 — transient database retry;
- TRN-003 — contract-first by-id endpoint;
- TRN-012 — idempotent order creation.

Each student task contains a manifest, ticket, deterministic scenario, reproduction command, visible verification, evidence requirements, reset command, and estimated duration. Their manifests reserve independent `task/TRN-###-baseline` branch names. The accepted checkpoint commit must be used to materialize those branches; the Phase 4 implementation itself does not create commits.

Mentor-only root-cause notes, hints, hidden tests, review checklists, and reference sources are maintained outside the student repository. All three references passed their reset → reproduce → fix → visible/hidden verify gates. Catalog expansion remains Phase 5 and has not started.
