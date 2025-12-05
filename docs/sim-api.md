# Omega sim API contract

`/v1/sim/tick` is the minimal bridge between Paper clients and the shared Omega simulation. It is stateless HTTP; state is stored in a JSON file (local path or gcsfuse mount).

## Request (JSON)
```json
{
  "player_id": "uuid-or-label",
  "pose": { "pos": { "x": 0.0, "y": 64.0, "z": 0.0 }, "yaw": 0.0, "pitch": 0.0 },
  "inputs": { "forward": false, "back": false, "left": false, "right": false, "jump": false, "sneak": false },
  "client_time_ms": 1716400000000
}
```

## Response (JSON)
```json
{
  "tick": 1,
  "state_version": "tick-1",
  "server_time_ms": 1716400001000,
  "view": {
    "anchors": [{ "id": "omega-root", "kind": "origin", "pos": { "x": 0, "y": 64, "z": 0 } }],
    "entities": [{ "id": "player-<uuid>", "kind": "player-shadow", "pos": { "x": 0, "y": 64, "z": 0 }, "yaw": 0, "pitch": 0 }],
    "barriers": [{ "min": { "x": -1, "y": 64, "z": -1 }, "max": { "x": 1, "y": 64, "z": 1 } }],
    "ui": { "title": "Ω void terminal", "hotbar": ["You are in the shared Ω simulation", "Tick 1", "You reported: (0.00,64.00,0.00)"] }
  }
}
```

All structs live in `spec/src/lib.rs` (`SimTickRequest`, `SimTickResponse`, `Pose`, `Vec3`, etc.) so Rust API and any clients can share the same schema.

## Storage
- `SIM_STATE_PATH` env var controls where the JSON state is read/written (default `/tmp/omega-sim-state.json`).
- For Cloud Run + GCS: mount a bucket via `gcsfuse` and point `SIM_STATE_PATH` at the desired object path, e.g. `/mnt/gcs/9∞/labels/demo/state.json`.
- State format:
```json
{ "tick": 42, "players": [ { "player_id": "...", "pose": {...}, "last_inputs": {...} } ] }
```

## Auth
- Optional `X-Auth-Token` header: set `OMEGA_TICK_TOKEN` to require it. Use short-lived per-client tokens.

## Smoke test
```
PORT=8888 SIM_STATE_PATH=/tmp/omega-sim-state.json cargo run -p api
curl -X POST http://localhost:8888/v1/sim/tick \
  -H 'Content-Type: application/json' \
  -d '{"player_id":"demo","pose":{"pos":{"x":0,"y":64,"z":0}},"inputs":{"forward":true}}'
```
