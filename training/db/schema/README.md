# Training schema

Training-owned schema objects are currently created idempotently by `../base-seed/apply.sql`. They are isolated by the `Training` prefix. Phase 2 will move plugin-owned tables to nopCommerce migrations when `Nop.Plugin.Training.Api` exists.

