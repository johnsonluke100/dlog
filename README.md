# dlog workspace

Root Rust workspace for the dlog universe.

Crates:
- `spec`    → shared types and models (labels, balances, planets, Ω paths, landlocks)
- `corelib` → universe logic (state machine, balances, snapshots, φ-gravity, Ω helpers, land registry)
- `api`     → HTTP server exposing the node API

Top-level:
- `Dockerfile`         → container build for the `api` binary
- `docker-compose.yml` → orchestration for running `api` in Docker
- `dlog.toml`          → node configuration (bind address, name, phi tick rate)

Use `dlog.command` on the Desktop as the only launcher.
