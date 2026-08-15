# Architecture

The lab preserves nopCommerce's application architecture and adds training infrastructure at the edges.

```text
HTTP -> Nop.Web / training plugin controller
     -> Nop.Services application service
     -> IRepository<TEntity> / INopDataProvider
     -> SQL Server
     -> mapping -> HTTP response

Events -> IEventPublisher -> consumers -> Redis / later integration adapters
```

Training-only HTTP behavior is implemented in `Nop.Plugin.Training.Api`. Its controllers call existing nopCommerce services for customers, products, inventory, orders, and payments; direct data-provider access is limited to the Phase 1 training outbox read model. Infrastructure, the source OpenAPI contract, and deterministic state live under `training/`. Core nopCommerce business code remains unchanged.

The Compose project is named `commerce-engineering-lab`. Its destructive boundary is limited to containers, networks, and named volumes carrying that project label plus ignored local runtime files. The app data volume preserves the nopCommerce plugin registry across image rebuilds; `start.ps1` also carries an existing Phase 1 registry into that volume during the first compatible upgrade.
