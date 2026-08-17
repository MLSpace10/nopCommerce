# Retry transient product-read failures

Type: bug

## Business context

The product lookup backs an internal support workflow. A short database connectivity interruption currently turns a safe read into an immediate failed request, although the database is available again within the request budget.

## Observed behavior

With the `database-transient` training fault selected, `GET /api/products/1` returns HTTP 500 after one attempt. The response header `X-Training-Fault-Attempts` reports the observed count.

## Expected behavior

The same request succeeds after a bounded retry for transient failures. A `database-permanent` failure is attempted once and remains an error. No write endpoint gains retry behavior.

## Steps to reproduce

1. Run `pwsh ./training/tasks/TRN-001/reproduce.ps1`.
2. Capture the status and attempt-count header.
3. Trace the request through the controller, application service, and controlled fault boundary.

## Example curl

```text
curl -H "X-Training-Api-Key: <local-key>" http://localhost:8080/api/products/1
```

## Example log

```text
Controlled transient database timeout. request=synthetic-correlation-id attempts=1
```

## Compatibility constraints

- Retry only transient failures on this safe read path.
- Use exponential backoff and jitter with a strict attempt bound.
- Do not retry permanent errors or any order/payment write.
- Propagate request cancellation where the retry mechanism permits it.

## Acceptance criteria

- Transient profile returns 200 with exactly three observed attempts.
- Permanent profile returns 500 with exactly one observed attempt.
- Existing success and 404 behavior remain compatible.
- Build, focused tests, real HTTP, and scenario verification pass.

## Available commands

- Reproduce: `pwsh ./training/tasks/TRN-001/reproduce.ps1`
- Visible verification: `pwsh ./training/tasks/TRN-001/visible-tests/verify.ps1`
- Reset: `pwsh ./training/scripts/scenario.ps1 reset TRN-001`

## Out of scope

- Global database retry, write retries, schema changes, and external HTTP retry policies.
