# dlog workspace

Root Rust workspace for the DLOG / Ω universe.

Crates:

- `spec`      → shared types and models (addresses, planets, money, sky, omega-fs, land, genesis, devices)
- `corelib`   → universe logic (state machine, balances, interest ticks)
- `core`      → coordination layer between phi physics and chain logic
- `omega`     → Omega Phi 8888 Hz "Leidenfrost Flame Engine" (Rust)
- `sky`       → SkyLighting logic: slideshows, frame selection, phi-based sky timeline
- `api`       → HTTP server exposing a minimal JSON API over universe + sky + canon-spec helpers

Top-level:

- `Cargo.toml`          → workspace definition
- `rust-toolchain.toml` → pinned toolchain for reproducible builds
- `dlog.toml`           → node configuration (bind, phi, paths)
- `Dockerfile`          → container build for the `dlog-api` binary
- `docker-compose.yml`  → simple compose stack for local docker runs

Launcher:

- `~/Desktop/dlog.command` is the ONLY launcher that spins everything up:
  - Exports `OMEGA_ROOT`
  - Starts `dlog-omega` in the background (endless tuning fork)
  - Runs `dlog-api` in the foreground
