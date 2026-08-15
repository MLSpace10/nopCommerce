# ADR 0003: Docker Compose profiles and project-scoped state

Status: accepted, 2026-08-15.

Use Compose profiles `core`, `integration`, `chaos`, and `observability`. Phase 1 implements `core`; later phases activate other profiles only when a pilot task needs them. All containers and named volumes use the fixed Compose project `commerce-engineering-lab`, so reset can validate and constrain its destructive scope.

