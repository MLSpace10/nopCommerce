# Add a contract-first product details endpoint

Type: feature

## Business context

Support tooling needs one product-details read that combines the product identity, nullable GTIN, current total stock, and category identifiers. Callers currently assemble this information through separate paths.

## Observed behavior

`GET /api/products/1/details` returns 404 and the route is absent from the source OpenAPI document. The existing product collection remains available.

## Expected behavior

Add the source contract first, then implement the endpoint through existing nopCommerce application services. Product 1 returns 200; unknown, zero, and negative IDs return 404. A missing GTIN is serialized as JSON `null`.

## Steps to reproduce

1. Run `pwsh ./training/tasks/TRN-003/reproduce.ps1`.
2. Confirm the collection returns 200 and the new route returns 404.
3. Inspect the source and runtime OpenAPI documents.

## Example curl

```text
curl -H "X-Training-Api-Key: <local-key>" http://localhost:8080/api/products/1/details
```

## Example log

```text
GET /api/products/1/details completed 404 route-not-available
```

## Compatibility constraints

- Do not remove or change `GET /api/products` or `GET /api/products/{productId}`.
- Response fields are `id`, `name`, `sku`, nullable `gtin`, `stockQuantity`, and `categoryIds`.
- Source and runtime OpenAPI must match with no unrelated generated churn.

## Acceptance criteria

- Existing product returns 200 with values from multiple existing sources.
- Unknown, zero, and negative IDs return 404.
- Nullable GTIN is represented correctly.
- Collection endpoint, contract lint/drift, build, tests, HTTP, and SQL fixture checks pass.

## Available commands

- Reproduce: `pwsh ./training/tasks/TRN-003/reproduce.ps1`
- Visible verification: `pwsh ./training/tasks/TRN-003/visible-tests/verify.ps1`
- Reset: `pwsh ./training/scripts/scenario.ps1 reset TRN-003`

## Out of scope

- Product writes, changes to existing response DTOs, pagination changes, and core nopCommerce refactoring.
