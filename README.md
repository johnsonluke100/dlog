# dlog workspace

Root Rust workspace for the DLOG / Ω universe.

Crates:

- `spec`      → shared types and models (addresses, planets, sky, money, omega-fs, land, genesis, devices, flight, solar system)
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

## Deployment (HTTP/3)

Cloud Run handles QUIC/TLS termination for `dlog_gold_http`. Use `./cloud.command deploy` or follow `docs/cloud-run.md` for a manual walkthrough targeting project `dlog-gold`, region `us-east1`, and service `api`.

## Omega HTTP-4 Edge

`dlog_gold_http` now exposes the first HTTP-4 JSON bridge:

- `POST /omega/handshake` → registers a session and emits DNS router hints.
- `POST /omega/frame`     → accepts frame envelopes and returns routing acks.

All traffic flows over HTTP/3 (QUIC) at the Cloud Run edge, then feeds the Rust-only Ω kernel behind the scenes.
