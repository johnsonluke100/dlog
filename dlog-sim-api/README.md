# dlog-sim-api

Minimal Axum service for `/v1/sim/tick` that treats a GCS bucket as the shared Ω filesystem.

## Storage layout
- Bucket is provided via `OMEGA_BUCKET`.
- Keys follow the Ω separator: `infinity;root.json`, `labels;<label_id>;state.json`, `sim;universe.json`, `sim;players;<player_uuid>;state.json`.
- World state lives under `world;chunks;<cx>;<cz>.json` (sparse block lists + version) and the block ledger under `ledger;blocks;<cx>;<cz>.json` (event window).

## Running locally
- Export `OMEGA_BUCKET` and make sure Application Default Credentials can read/write it (`GOOGLE_APPLICATION_CREDENTIALS` or `gcloud auth application-default login`).
- Optional: `PORT` (defaults to `8080`).
- `cargo run -p dlog-sim-api` then POST to `http://localhost:8080/v1/sim/tick`.

Example request:
```json
{
  "player_uuid": "00000000-0000-0000-0000-000000000000",
  "local_tick": 1,
  "position": { "x": 0.0, "y": 64.0, "z": 0.0, "yaw": 0.0, "pitch": 0.0 },
  "inputs": [ { "type": "Move", "dx": 1.0, "dy": 0.0, "dz": 0.0 } ],
  "block_updates": [
    { "x": 0, "y": 64, "z": 1, "block": "stone", "action": "place" },
    { "x": 0, "y": 64, "z": 1, "block": "stone", "action": "break" }
  ]
}
```

Response:
```json
{
  "universe_tick": 1,
  "render": [
    { "type": "PlaceArmorStand", "id": "as-origin", "x": 0.0, "y": 64.0, "z": 0.0, "yaw": 0.0, "pitch": 0.0 },
    { "type": "MoveArmorStand", "id": "player-00000000-0000-0000-0000-000000000000", "x": 0.0, "y": 64.0, "z": 0.0, "yaw": 0.0, "pitch": 0.0 },
    { "type": "Title", "text": "Ω tick 1 (local 1)" }
  ],
  "chunks": [
    { "cx": 0, "cz": 0, "version": 1, "blocks": [ { "x": 0, "y": 64, "z": 1, "block": "stone", "last_tick": 1 } ] }
  ]
}
```

## Cloud Run hints
- Build a container from the workspace and deploy with `OMEGA_BUCKET` set.
- Grant the service account `storage.objectAdmin` (or narrower write/read) on the bucket.
- Front with the existing HTTPS load balancer so Paper can call `https://dlog.gold/v1/sim/tick`.
