# Commerce Engineering Lab working rules

- Trace the existing flow and inspect callers and consumers before editing.
- Do not invent business rules. Make the smallest coherent change that satisfies the ticket.
- Preserve public APIs and backward compatibility unless the ticket explicitly changes a contract.
- Treat SQL, migrations, seeds, and persisted data as production-sensitive.
- Use async/await throughout asynchronous flows and propagate cancellation where the existing API permits it.
- Do not perform unrelated refactoring or fix unrelated failures.
- Build and relevant tests are required for every implementation change.
- API work requires a real HTTP verification; unit tests alone are not sufficient.
- Database writes require verification of persisted state.
- Never commit secrets or real personal, employer, or production data.
- Report blockers and unverified assumptions explicitly.
- Never run destructive operations against an unknown database. Training scripts must target only the explicit `commerce-engineering-lab` Compose project and `CommerceEngineeringLab` database.
- Students must not inspect mentor branches, solution patches, hidden tests, or mentor-only remotes.
- Do not create upstream nopCommerce issues or pull requests for training material.
- Do not commit, push, or publish branches unless the repository owner explicitly asks.

