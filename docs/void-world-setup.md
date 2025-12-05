# Void Paper world (step 1)

Goal: every local Paper 1.8.8 server is a disposable void renderer with a tiny spawn pad. The real state lives in Omega (Cloud Run + GCS).

## Build the helper plugin
```
mvn -f paper-void-plugin/pom.xml package
# jar: paper-void-plugin/target/void-terminal-0.1.0.jar
```

## Run a void world locally (itzg/minecraft-server)
```
docker run -d --name paper-void \
  -e EULA=TRUE \
  -e TYPE=PAPER \
  -e VERSION=1.8.8 \
  -e LEVEL_TYPE=FLAT \
  -e GENERATOR_SETTINGS="3;minecraft:air;1;" \
  -e GENERATE_STRUCTURES=false \
  -e ALLOW_NETHER=false \
  -e ALLOW_END=false \
  -p 25565:25565 \
  -v $(pwd)/paper-void-plugin/target/void-terminal-0.1.0.jar:/plugins/void-terminal.jar \
  itzg/minecraft-server:java8
```

What happens:
- World is generated as pure void (no terrain, no ores, no caves).
- Plugin builds a 3x3 bedrock pad at spawn (y=64), sets spawn one block above it, and exposes `/recenter` to rebuild + teleport.
- Deleting the world is fine; on next boot it re-creates the pad and re-syncs from Omega state.

## Step 2: minimal Cloud Run sim endpoint
- `api` now exposes `POST /v1/sim/tick` (Axum) that:
  - Accepts `{ "player_id": "...", "pose": { "pos": {x,y,z}, "yaw": 0, "pitch": 0 }, "inputs": {...} }`
  - Reads/writes a small JSON state file (default `/tmp/omega-sim-state.json`; set `SIM_STATE_PATH` to a gcsfuse-mounted object for GCS).
  - Returns a simple render plan: anchors, entities, barriers, UI text, plus tick/version.
- Smoke test:
```
PORT=8888 SIM_STATE_PATH=/tmp/omega-sim-state.json cargo run -p api

curl -X POST http://localhost:8888/v1/sim/tick \
  -H 'Content-Type: application/json' \
  -d '{"player_id":"demo","pose":{"pos":{"x":0,"y":64,"z":0}},"inputs":{"forward":true}}'
```
Expect a JSON body with `tick`, `state_version`, and a `view` listing anchors/entities/barriers/hotbar strings. Wire the Paper plugin to call this every few ticks with player pose and inputs.

## Step 3: Paper client stub → Omega sim
- Build the client plugin:
```
mvn -f paper-sim-plugin/pom.xml package
# jar: paper-sim-plugin/target/omega-sim-client-0.1.0.jar
```
- Drop/mount the jar into your Paper 1.8.8 server (`plugins/`). Config (`plugins/OmegaSimClient/config.yml`):
  - `api_base`: URL for the Cloud Run API (default `http://localhost:8888`).
  - `auth_token`: optional token for `X-Auth-Token`.
  - `tick_interval_ticks`: how often to POST a tick (default 10 ticks).
- Behavior:
  - Every interval, for each online player it POSTs `/v1/sim/tick` with UUID, pose, and inputs.
  - Parses the response view and spawns/updates invisible armor stands to represent `entities`.
  - Renders `barriers` to the client as barrier blocks (client-side only) and cleans them up when they disappear.
  - Shows the first hotbar line as an action bar and logs all hotbar lines to chat (throttled).
  - Command `/simtick` triggers a one-off tick for testing.
- Mount alongside the void helper so players spawn on a pad and see Omega-rendered entities in the void world.
- Shared contract lives in `spec/src/lib.rs` (SimTickRequest/Response, Pose, Vec3, etc.) so Rust API and clients stay in sync.

For non-Docker runs, set the same `level-type` and `generator-settings` in `server.properties` and drop the jar into `plugins/`.
