# dlog workspace

Root Rust workspace for the DLOG / Ω universe.

Crates:

- `spec`      → shared types and models (addresses, planets, config, constants, sky descriptors)
- `corelib`   → universe logic (state machine, balances, interest ticks)
- `core`      → coordination layer between phi physics and chain logic
- `omega`     → Omega Phi 8888 Hz "Leidenfrost Flame Engine" (Rust rework of omega_numpy_container)
- `sky`       → SkyLighting logic: slideshows, frame selection, phi-based sky timeline
- `api`       → HTTP server exposing a minimal JSON API over the universe + sky

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
