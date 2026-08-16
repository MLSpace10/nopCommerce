# Security and synthetic data

The lab uses only synthetic identities and development-only placeholder credentials. Local `training/.env`, runtime app settings, and plugin-registry snapshots are ignored. Copyable tickets and logs must redact API keys, passwords, tokens, connection strings, personal data, and machine-specific paths.

`verify-task-framework.ps1` rejects common private-key, AWS-key, and GitHub-token forms and mentor artifacts in the student task tree. This is a guardrail, not a substitute for review or a dedicated organization secret scanner.

Database scripts are restricted to `CommerceEngineeringLab`; Compose lifecycle scripts are restricted to `commerce-engineering-lab`. Scenario paths accept only `TRN-###`, preventing path traversal. SQL writes require persisted-state assertions and must not target an unknown database.

Mentor material is access-controlled separately. Student checkouts must never contain hidden tests, solution patches, hints, mentor notes, review checklists, solution branches, or mentor-only remotes.
