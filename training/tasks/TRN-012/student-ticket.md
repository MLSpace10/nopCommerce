# Make order creation idempotent

Type: bug

## Business context

Clients retry order creation after connection loss or an unknown response. The API accepts `Idempotency-Key`, but repeated requests currently create multiple orders and reduce stock multiple times.

## Observed behavior

Sequential and concurrent POSTs with the same key and payload return different order IDs. Retrying after the controlled `order-response-timeout` also creates another order. A reused key with a different payload is accepted.

## Expected behavior

The first successful result is persisted and replayed for the same key and payload. Concurrent requests converge on one order. Reusing a key with a different payload returns 409. Clients without the header retain existing behavior.

## Steps to reproduce

1. Run `pwsh ./training/tasks/TRN-012/reproduce.ps1`.
2. Capture returned order IDs and the SQL duplicate count.
3. Trace the order, order-item, inventory, and transaction boundaries.

## Example curl

```text
curl -X POST -H "X-Training-Api-Key: <local-key>" -H "Idempotency-Key: <unique-key>" -H "Content-Type: application/json" --data '{"customerId":4,"productId":1,"quantity":1}' http://localhost:8080/api/orders
```

## Example log

```text
order-create key=<redacted> outcome=duplicate orderIds=[synthetic-id-1,synthetic-id-2]
```

## Compatibility constraints

- Persist the key, request identity, and replayable result.
- Same key/same payload returns the original successful result.
- Same key/different payload returns 409 without another order.
- Parallel requests and retry after lost response create one business order.
- Keep database work atomic and do not hold a transaction during response delay.
- Never log the raw key or request secrets.

## Acceptance criteria

- Sequential, parallel, response-timeout, and payload-conflict cases pass via real HTTP.
- Exactly one order and one persisted idempotency result exist per successful key.
- Requests without a key remain backward compatible.
- Build, focused tests, related GET, SQL assertions, reset, and complete-diff review pass.

## Available commands

- Reproduce: `pwsh ./training/tasks/TRN-012/reproduce.ps1`
- Visible verification: `pwsh ./training/tasks/TRN-012/visible-tests/verify.ps1`
- Reset: `pwsh ./training/scripts/scenario.ps1 reset TRN-012`

## Out of scope

- Payment idempotency, distributed brokers, cross-service sagas, and unrelated order workflow changes.
