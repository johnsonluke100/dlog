# dlog workspace

Root Rust workspace for the dlog universe.

Crates:
- `spec`    → shared types and models (labels, balances, landlocks, planets, Ω paths, tick tuning, MC bridge types)
- `corelib` → universe logic (state machine, balances, snapshots, φ-gravity, Ω helpers, land registry, MC player state)
- `api`     → HTTP server exposing the node API

Top-level:
- `Dockerfile`         → container build for the `api` binary
- `docker-compose.yml` → orchestration for running `api` in Docker
- `dlog.toml`          → node configuration (bind address, name, phi tick rate)

HTTP endpoints (current sketch):
- `GET  /health`
- `GET  /config`
- `GET  /snapshot`
- `GET  /balance?phone=&label=`
- `POST /transfer`
- `GET  /planets`
- `GET  /phi_gravity?id=earth`
- `GET  /ticks/tune?fps=&planet=`
- `GET  /omega/master_root`
- `GET  /omega/label_path?phone=&label=`
- `GET  /land/locks?world=`
- `POST /land/mint`
- `POST /mc/register`  (Minecraft client → tuned φ flight/fall per frame)

Use `dlog.command` on the Desktop as the only launcher.
