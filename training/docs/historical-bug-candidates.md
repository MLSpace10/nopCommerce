# Historical bug candidates

These candidates use only public nopCommerce issues and commits. "Candidate" does not mean accepted: each must still reproduce deterministically on its parent commit or be consciously transplanted as the same failure class onto the pinned training platform.

| Issue | Public symptom | Fix commit in local history | Candidate use | Phase 0 status |
| --- | --- | --- | --- | --- |
| [#5593](https://github.com/nopSolutions/nopCommerce/issues/5593) | One app instance cannot clear Redis keys created by another instance, leaving stale settings/cache data. | `5acbd99662` | Multi-instance stale distributed cache | Provenance verified; local reproduction pending |
| [#8105](https://github.com/nopSolutions/nopCommerce/issues/8105) | Periodic timer jitter can cause a scheduled run to be skipped when the elapsed-time check rounds at the boundary. | `0ae3478d51` | Deterministic clock/scheduler boundary task | Provenance verified; local reproduction pending |
| [#8163](https://github.com/nopSolutions/nopCommerce/issues/8163) | A crashed/restarted guest cleanup leaves a temporary table that breaks the next execution. | `db61230703` | Recovery-safe SQL and idempotent operational job | Provenance verified; local reproduction pending |
| [#8176](https://github.com/nopSolutions/nopCommerce/issues/8176) | A multi-instance/type-discovery race triggers `TypeInitializationException`. | `8fe0d084bf` | Concurrency and process-startup investigation | Commit verified; issue page/reproduction pending |
| [#8210](https://github.com/nopSolutions/nopCommerce/issues/8210) | Undisposed `SKCodec` objects leak file descriptors under repeated default-image thumbnail generation. | `e59e3297c5` (plus test `1ce84ab09d`) | Linux resource-leak task | Provenance verified; container reproduction pending |
| [#8231](https://github.com/nopSolutions/nopCommerce/issues/8231) | A vendor can modify another vendor's product attribute combinations. | `95a8d983b9` | Tenant/vendor authorization data isolation | Commit verified; HTTP reproduction pending |

The first pilot tasks remain the required synthetic TRN-001, TRN-003, and TRN-012. Historical candidates are not substituted for those pilots.

