# ADR 0001: SQL Server is the primary training database

Status: accepted, 2026-08-15.

Use SQL Server 2022 Developer for the primary lab. It is supported by the pinned nopCommerce source, is free for development/test use, and matches the curriculum's need for transaction, isolation, query-plan, migration, and failure-injection work. PostgreSQL remains a future compatibility profile; maintaining two primary baselines now would reduce determinism.

