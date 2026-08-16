# Updating the upstream checkpoint

Upstream updates are performed on a dedicated platform-maintenance branch, never inside a student baseline or solution branch.

1. Record the old and proposed upstream SHAs and review license/release changes.
2. Re-run the audit for .NET, database support, Docker, plugin, service, repository, cache, event, and test conventions.
3. Rebase or merge the accepted platform checkpoints without copying mentor refs.
4. Build the solution and run targeted and broader tests.
5. Run platform bootstrap/reset, HTTP, SQL, Redis, API, OpenAPI, and task-framework verification.
6. Validate every existing task baseline independently; update only tasks genuinely affected by upstream behavior.
7. Record compatibility decisions and unresolved limitations before accepting a new checkpoint.

Never publish training issues or pull requests to upstream nopCommerce, and never silently move a baseline to a new upstream parent.
