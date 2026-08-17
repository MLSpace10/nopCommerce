# Expected evidence

- Root-cause trace from HTTP to the controlled read boundary.
- Failure classification and rejected global/write retry alternatives.
- Tests proving transient success, permanent single attempt, attempt bound, and cancellation behavior.
- Copyable HTTP evidence with statuses and `X-Training-Fault-Attempts`.
- Scenario SQL verification and complete-diff review.
