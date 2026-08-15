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

Training-only HTTP behavior belongs in `Nop.Plugin.Training.Api` during Phase 2. Infrastructure and deterministic state live under `training/`. Core nopCommerce code is changed only where a task baseline intentionally introduces or fixes a defect.

The Phase 1 Compose project is named `commerce-engineering-lab`. Its destructive boundary is limited to containers, networks, and named volumes carrying that project label plus the ignored local runtime appsettings file.

