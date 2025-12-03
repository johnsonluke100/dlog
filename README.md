# dlog workspace

Root Rust workspace for the DLOG / Ω universe.

Crates:

- `spec`      → shared types and models (addresses, planets, sky, money, omega-fs, land, genesis, devices, flight, solar system)
- `corelib`   → universe logic (state machine, balances, interest ticks)
- `core`      → coordination layer between phi physics and chain logic
- `omega`     → Omega Phi 8888 Hz "Leidenfrost Flame Engine" (Rust)
- `sky`       → SkyLighting logic: slideshows, frame selection, phi-based sky timeline
- `api`       → HTTP server exposing a minimal JSON API over universe + sky + canon-spec helpers, plus `/v1/hypercube/summary` and a Paper WebSocket bridge (`/ws/paper`, `/v1/paper/status`)

Top-level:

- `Cargo.toml`          → workspace definition
- `rust-toolchain.toml` → pinned toolchain for reproducible builds
- `dlog.toml`           → node configuration (bind, phi, paths)
- `Dockerfile`          → container build for the `dlog_gold_http` binary
- `Dockerfile.api`      → container build for the `api` binary (binds to `$PORT`, defaults 8080)
- `docker-compose.yml`  → simple compose stack for local docker runs
- `docs/hypercube.md`   → condensed canon-spec (hypercube) summary for quick reference

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
- `GET /omega/status`     → snapshots the gateway id, boot time, session count, and wired services.
- `POST /identity/mojang` / `/identity/web` → forward Mojang or DLOGcraft login assertions into the presence service so the HTTP‑4 kernel knows which phone-number / label belongs to each session.

All traffic flows over HTTP/3 (QUIC) at the Cloud Run edge, then feeds the Rust-only Ω kernel behind the scenes. The DNS router now performs real lookups against its Ω-path table (with hierarchical fallbacks) so client logs show which subsystem will receive each namespace even before the full services are implemented. The Infinity bank stub responds to `balance_query` and `transfer` frames, mutating an in-memory ledger so client prototypes can exercise real state changes.

### HTTP-4 Client Prototype

- `dlog_http4_client` demonstrates how to speak the bridge: it handshakes, issues a balance query, fires a transfer from COMET → FUN, and then re-queries balances so you can see the ledger mutation notes in the server ack payloads.

### Sha-less Infinity Blocks

- `corelib` now renders `UniverseSnapshot.master_root_infinity` by hashing the height + balances with SHA-512 ‖ BLAKE3 (1024 bits) and expressing the result in Infinity base (octal) with the Ω semicolon framing: `;∞;sha-less;…;`. This replaces the old placeholder scalar so every block height produces a deterministic sha-less root that can be stored under the 9∞ filesystem.

### Presence Service

- `presence_service` (Axum) tracks Mojang and DLOGcraft sessions keyed by phone number. Set `PRESENCE_BASE_URL` (default `http://127.0.0.1:4000`) so `dlog_gold_http` can call it during `/omega/handshake`, ensuring only known phone-number identities receive Ω access.
Frame acknowledgements currently include stubbed service logs from the DNS router, Infinity bank, mining dispatcher, speaker engine, and game loop so client developers can see how payloads will fan out once full implementations land.
