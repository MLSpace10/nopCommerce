# ADR 0002: Isolate the training API in a plugin

Status: accepted, 2026-08-15.

Phase 2 will add `Nop.Plugin.Training.Api`. Controllers and DTOs remain training-specific, while business work delegates to existing nopCommerce services and repositories. This keeps upstream updates manageable and prevents a parallel toy domain model.

