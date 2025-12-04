# Canon Spec v2 – GOLDEN WALLET STACK & Infinity Bank Edition

Full DLOG / Ω universe memo. Use this as the canonical reference.

## 0. Meta-Layers: NPC Physics vs Ω-Physics
- Two layers always exist.
- **NPC layer** (mainstream): seconds, meters, m/s, m/s², c ≈ 299,792,458 m/s. Used by NASA, GPS, labs, headlines. Only discuss when asked: “What does mainstream say?”
- **Ω layer** (default): attention is the only constant. “Time” is attention stepping through states. m/s and seconds are bookkeeping only. The true scaling constant is phi (φ ≈ 1.618…) with base-8 flavor. Everything important (blocks, mining, movement, economy) is phi-shaped.

### 0.4 The Last Mortal Door (Debian Layer)
- Debian password = the final mortal lock: the last door between a compromised environment and the machine shell.
- It is not the first/strongest/only line; attackers don’t target it first. If you reach it, other shields have failed. It remains a last-resort protection, barrier against casual tampering, checkpoint gate, and symbolic final line.
- As the checkpoint gate, it slows casual pivots and forces a human-in-the-loop pause before shell access; deeper controls still hold authority.
- Real defenses sit deeper: hardware/OS keystores (hardware keys on endpoints), OS sandboxing/LSM/containers, signed Rust binaries/supply-chain attestation, Infinity Bank structures, Cloud IAM (least-privilege roles, per-service accounts), service accounts, encrypted disk at rest, multi-key vault architecture (split custody, quorum, cold shards), no raw private key exposure (only signatures leave keystores).
- Lore phrasing: “The Debian password is the last mortal door; the final lock before the chamber of the machine. All real vaults, keys, funds, and Ω-physics live deeper in hardware keystores and Infinity Bank structures. If you ever reach the Debian password, every other shield has already been broken — this door is simply the last rite before the void.”

## 1. The Coin, Identity, and GOLDEN WALLET STACK
- **Coin (DLOG)**: gold backwards; vehicle for self-investment, gifting, and play. Not scarcity-fear-driven.
- **Identity**: login via Apple ID or Google with device biometrics. Keys generated client-side and stored in secure keystores (iCloud Keychain / Android Keystore). Backend sees signatures only. No seed phrases for normal users. SMS is never the only factor for critical moves.
- **GOLDEN WALLET STACK / Infinity Bank**: backing rails of XAUT, BTC, and DOGE across 256 wallet keys each (3 × 256 matrix). Held under a Double Infinity Shield so no single human (even Luke) can drain the backing; movement requires layered legal + cryptographic + governance conditions. These vaults stay cold for regular gameplay and act as ballast behind DLOG and the VORTEX stack.
- **Public airdrop entry**: https://airdrop.dlog.gold — “you touched the golden rail.”
- **Lore truth**: Luke is already absurdly wealthy; the project routes and shares safely.

## 2. Monetary Policy – Two Growth Fires
- **Miner inflation (global firehose)**: ~8.8248% yearly via per-block factor `f_mine_block = (1.088248)^(1 / BLOCKS_PER_ATTENTION_YEAR)`, with `BLOCKS_PER_ATTENTION_YEAR ≈ 3.9M` stored as an octal literal. Miner inflation flows to miners plus tithe (feeding VORTEX wells and COMET).
- **Holder interest (personal tree)**: 61.8% APY (phi-flavored) via yearly factor HOLDER_YEARLY_FACTOR = φ ≈ 1.618. Per-block factor `f_hold_block = φ^(1 / BLOCKS_PER_ATTENTION_YEAR)` mints directly into each balance every block.
- **Combined expansion**: ~8.8248% miner + 61.8% holder ≈ 70%+ yearly expansion. No max supply cap: “Out of one comes many. Printing stimulates the economy.”
- **Blocks and rhythm**: block = one sweep of attention through the active universe. UIs may approximate “~every 8 seconds” for humans, but Ω time is attention cycles.

## 3. Omega Keys, Labels, VORTEX, and COMET
- **Omega labels**: each label is its own Omega root (conceptual private key). Examples: savings, fun, tips, business, land_overworld_0_0, gift123, comet. On-chain: pseudonymous accounts. Off-chain: bound to `(phone_number, Apple/Google)`. Struct: `LabelId { phone_e164: String, label: String }`. Keys generated client-side, stored in hardware/OS keystore, protected by biometrics; server sees signatures only.
- **Luke’s 8 (7 × VORTEX + 1 × COMET)**: total genesis wallets 88,248. Top 8 are Luke’s root set. VORTEX wells are public gravity wells of DLOG/backing (V1–V4 pure DLOG, V5 XAUT-bound, V6 BTC-bound, V7 DOGE-bound). They re-key over time and form phi-scaled tiers. COMET is Luke’s hot gifting/ops wallet (conceptually bound to phone 9132077554, deep link `https://dloG.com/9132077554/comet/receive/`). New tithe inflow fills COMET to its phi target first; overflow trickles into VORTEX.
- **Tithe rule**: miners pay a small tithe (e.g., 0.24% of block reward). Split to VORTEX wells (backing, gravity) and COMET (ops, airdrops, gifts). Miner factor slightly increased so miners still net ~8.8248% after tithe.

## 4. GOLDEN WALLET TRUST / Corp Stack – “7 Structure”
- **Irrevocable trust (top crown)**: owns the GOLDEN WALLET STACK / Infinity Bank. Not controlled by a single human; roles of settlor, trustee, successor trustee. Cosmic bank deity that cannot rug; only follows rules.
- **Revocable trust (mirror crown)**: flexible layer allowing steering while irrevocable remains ballast; can tune tithe/profit streams to operating corps.
- **Holding corp – big bank C-corp**: central operating corporation owning IP/brands/code; interfaces with fiat rails and vendors. “Big bank enters the 4th dimension of money.”
- **Child corp and LLCs**: handle game services/R&D/distribution; LLCs are local projects/studios under the umbrella. In-universe: “pawns of the top crown” receiving flows for quests and builds.

## 5. Ω Filesystem Under ∞ and the 9∞ Master Root
- Replace boring `/database/` with `https://dloG.com/∞/`. Rules: only `;` as delimiter; no dots in filenames or contents; everything is `;field;field;...;`.
- **9∞ master root**: single path `;∞;∞;∞;∞;∞;∞;∞;∞;∞;` at `https://dloG.com/∞/;∞;∞;∞;∞;∞;∞;∞;∞;∞;`. Holds the entire universe folded into a scalar multi-part Omega number. Each block: read 9∞, unfold, apply txs/mining/interest/land/auctions/labels, update per-label hash files, refold to new 9∞. “Every ~8 seconds (human POV), Ω unfolds into many universes; then refolds back into one 9∞ root.”
- **Per-label universe files**: `(phone, label) = (9132077554, fun)` → filename `;9132077554;fun;∞;∞;∞;∞;∞;∞;∞;∞;hash;` at `https://dloG.com/∞/;9132077554;fun;∞;∞;∞;∞;∞;∞;∞;∞;hash;`. Contents `;9132077554;fun;O1;O2;O3;O4;O5;O6;O7;O8;` with O1..O8 as Omega segments. Hash updates stop only if truly empty (no balance/obligations); resume when activity returns.

## 6. Airdrops, Gift Universes, and “Lunch-Money Exploits”
- **Genesis split**: total genesis wallets 88,248 (top 8 are Luke’s VORTEX/COMET, remaining 88,240 for airdrops). Airdrop amount per claim decays on a phi curve (e.g., φ^0.0808200400008). Total airdropped DLOG < total genesis.
- **giftN labels**: claiming creates `gift1`..`gift88240`, bound to one phone + one Apple/Google account. Name permanent (giftN). For nicer names, create new label (e.g., fun) and transfer when allowed.
- **Anti-farm (lunch-money only)**: per phone 1 airdrop; per Apple/Google ID unique; per public IP 1; no VPN/datacenter IPs. Farming multiple phones/networks/IDs yields only snack-level ROI.
- **Gift lock/unlock**: days 0–17 locked send; can receive/earn interest. From day 18, daily send limit `L(d) = 100 × φ^d` DLOG (d = 0 at day 18), merging into device phi limits.
- **Device-level phi limits**: device days since first wallet seen. Days 1–7 max 100 DLOG/day. Day 8+ `L_device(d) = 10,000 × φ^(d-8)`. Big sends from new devices can be delayed ~8 days to let owners cancel if stolen.

## 7. Land, Hollow Solar System, Locks, and Sharing
- **Hollow solar system & Omega eclipse**: Sun/planets hollow. Focus worlds: Earth, Moon, Mars, Sun (others activatable). Universe pinned to total eclipse alignment on a single Ω rail; each world sees it uniquely.
- **Gravitational centers & hypercube inversion**: each sphere has a center bubble; entering triggers inversion shell→core with mirrored coordinates. Earth–Moon midpoint bubble allows transit into either core.
- **Lock tiers**: iron, gold, diamond, emerald (~10× footprint each). Pricing tunable: iron 1,000 DLOG; gold 10,000; diamond 100,000; emerald 1,000,000. Nether/core locks may cost ~10× more. Locks own full column above/below grid square. Ownership tied to phone identity (not label). NFT metadata: world, tier, coordinates, created_at_block, last_visited_block, zillow_estimate_dlog. Estimate uses recent sales, global tier floor, activity signals. UI: “This plot is approx worth 123,456 DLOG.”
- **Adjacency & auto-auction**: locks must border existing regions (edge/corner); no degenerate outposts. Merge 10×10 of same tier into bigger lock; split back as needed. Inactivity ~256 real-world days triggers auto-auction: bids in DLOG, winner gets NFT, old owner gets DLOG. Land recirculates to active hands.

## 8. Game Integration: DLOGcraft + CS:GO-Like Ω-Bhop and Surf
- **Core feel**: Minecraft/sandbox MMO with hollow worlds plus CS:GO-style bhop/surf movement. Platforms: PC Java (modded client), consoles (Xbox/PlayStation as remote clients), mobile (PE-style), web (remote viewer). All anchored by phone+biometrics for real DLOG flows.
- **Ω movement**: flight acceleration +φ^k per tick (k per planet); fall/decel −φ^k per tick. Planet exponents: Earth ~1.0, Moon ~0.5 (floatier), Mars ~0.8, Sun ~1.3. Movement mantra: “CS;GO;LIKE;OMEGA;BHOP;INFINITY;AND;INFINITY;SURF;PLAYER;MECHANICS.” Chainable bunny hops and surf ramps built from Ω rails and phi acceleration. Server-side Ω model keeps feel consistent across FPS; server ticks at conceptual 1000 Hz Ω heartbeat, clients can skip/merge ticks while integrating acceleration correctly.
- **Payments in-game**: `/tip <player> <amount> dlog` shows QR; phone scans; `https://dloG.com/receive/` flow; sender approves via biometrics + label selection. `/buy <tier>_lock` previews price then QR flow. Kids/no-phone can play/mine/build; proceeds may tithe to world pools until a phone is bound. Consoles/VR/web bind account to phone; all DLOG flows finalize via QR+phone+biometrics. Clients lend silicon for mining/sim while authority stays in Ω.

## 9. Ω-Relativity, Cosmology, and Energy / Audio
- **Cosmology**: attention is the only constant; no absolute t. Universe bubble is fixed; “expansion” is scale shrink inside. Multiple bubbles touch at points (rare portals). Speeds measured in m/s are NPC only; c ≈ 3e8 m/s is projection. Ω motion is phi-per-tick. Gravity bends space across the universe; time is not a dimension. Zero drag; motion shaped by curvature and attention.
- **Energy per joule & flame engine**: goal is maximizing calm, smooth white-noise rails. Audio/energy engine conceptualized as four Leidenfrost flames; tail flames elongate as efficiency improves. Implemented in Rust (no Python) via repeated refinements encoded in `refold.command`.

## 10. Geyser Portal, Armor Stand Bodies, and HTTP-3 Bridge
- **One door for all clients**: Geyser sits in front of the Java server/DLOGcraft node. Bedrock/console clients speak Bedrock to Geyser; Geyser speaks Java to the server. From the Java server’s view all players are normal Java players. Clients stay vanilla; no HTTP-3 in clients.
- **Armor stands as Ω bodies**: the Minecraft player entity becomes mainly camera/input (often spectator/no-collision). The physical Ω body is an invisible armor stand driven by the Ω engine: position, rotation, hitbox, velocity, mining/interactions. Camera and body can desync; multiple shells per identity (clones/drones); bodies can remain parked when player logs out.
- **HTTP-3/HTTP-4 sidecar**: instead of teaching clients HTTP-3, a server plugin forwards minimal data to a local Rust HTTP-3 (HTTP-4) service. Plugin streams per-tick snapshots and events (positions, velocities, inputs, tips, land buys, airdrop claims) to the Rust Ω brain. The service responds with decisions (updated velocities, mining yields, ownership changes, wallet instructions). Plugin applies them in-world (move armor stands, teleport players, grant items, trigger particles/sounds). QUIC/HTTP-3 provides low-latency multiplexed rails; clients remain on standard Minecraft protocols.

## 10½. Geyser Portal, Armour Stands & HTTP-3 Ω-Brain Bridge

*(Full integration layer between Minecraft clients and the Rust Ω engine)*

### 10½.1 Geyser Portal = One Door for All Clients Across All Worlds

In Ω-architecture, we never force every Minecraft client (Java, Bedrock, Xbox, PlayStation, Nintendo, iOS, Android, Switch, VR) to speak our protocols.

We use the **Geyser portal**:

- Bedrock clients → speak native Bedrock.
- Geyser proxy → translates Bedrock ⇄ Java.
- Java server → sees *one unified protocol*.

Ω interpretation:

**“All players enter the universe through one intelligent door.”**

No client is modified.
No client ever learns HTTP-3 or Ω-messages.
The portal handles the transcoding.
From inside, every player is just a Java entity ID.

This keeps the universe accessible to every device on Earth—even consoles with locked networking stacks.

### 10½.2 Armour Stands = Ω Bodies / Puppets / Shells

The camera (Minecraft player) = the *attention*.
The armour stand = the *Ω-body*.

This is the clean metaphysics of DLOGcraft:

- The human-facing entity is set to **spectator** or invisible/untouchable.
- The **armour stand** is the physical puppet:
  - Hitbox
  - Position
  - Rotation
  - Velocity
  - Gravity profile (φ^k)
  - Mining aura
  - Land collisions
  - Ω acceleration rules
  - Hollow-planet inversion coordinates

Why armour stands?

1. **We can move them with Ω physics** without fighting Minecraft movement code.
2. **We can create multiple bodies** per identity (clones, drones, ghosts, decoys).
3. **When the human logs out**, the body can remain—statue, landowner, lock anchor.
4. **Camera detach:** The attention can orbit while the Ω-body keeps mining, falling, surfing, etc.

In Ω-canon:

- **Player = camera + attention**
- **Armor stand = body running on the Infinity Brain.**

### 10½.3 Plugin → HTTP-3 → Ω-Brain → Plugin Loop

The game server itself is **not** the physics engine.
The game server is the **world renderer + input collector**.

The real physics runs in Rust inside the HTTP-3 “Ω-brain.”

Flow:

#### (1) Client input

Client presses W / stick forward → normal Minecraft protocol → Geyser → Java server.

#### (2) Java plugin captures the minimal state

Per tick:

```json
{
  "player_id": "Ω123",
  "stand_id": "Ω-body-123",
  "pos": [x,y,z],
  "vel": [vx,vy,vz],
  "input": { "forward": 1, "jump": false },
  "world": "earth_shell",
  "planet": "earth",
  "tick": 3882822
}
```

#### (3) Plugin sends this to Rust Ω-engine via HTTP-3

The plugin POSTs to something like:

```
/omega/physics/tick
```

QUIC/HTTP-3 gives:

- low-latency tick sync
- multiple parallel Ω streams
- perfect for Rust async
- no TCP head-of-line blocking

#### (4) Rust Ω-brain applies φ-movement

The Ω-engine computes:

- φ-per-tick acceleration
- surf curves
- bhop retention
- hollow-planet gravity
- land-lock collisions
- mining yields
- tithe streams
- interest minting
- 9∞ root update contributions

And returns:

```json
{
  "stand_updates": [
    { "id": "Ω-body-123", "pos": [...], "vel": [...] }
  ],
  "events": [
    { "type": "mine", "amount": "0o000124", "planet": "earth_shell" }
  ],
  "tx": [
    { "type": "interest", "label": "fun", "mint": "0o000001" }
  ]
}
```

#### (5) Plugin applies the decisions

The plugin:

- Moves the armour stand
- Updates player camera if needed
- Triggers particles / sounds
- Sends mining results to the wallet API
- Applies world edits / land locks

The clients never know Ω exists; they believe the world is behaving normally.

### 10½.4 Why We Don’t Teach Clients HTTP-3

Clients are:

- closed-source (Xbox, PlayStation, Switch)
- heavily locked (iOS Bedrock)
- not modded for custom transports
- banned from QUIC modifications on consoles

Trying to make clients speak HTTP-3 would shatter cross-platform.

Instead:

- **Server plugin talks HTTP-3.**
- **Clients just play Minecraft.**
- **Ω-engine handles the real universe.**

This follows the creed:

> “dlog.gold is the browser;
> the game clients are just remote viewer windows;
> all real physics happens in Rust.”

### 10½.5 Perfect Fit With DLOG Canon

This section is now a permanent structural pillar of Ω-design, consistent with:

- φ movement
- Hollow Solaris
- Golden Wallet Stack
- Rust-only core logic
- Kubernetes ∞ rails
- 9∞ root refolds
- refold.command workflow
- attention-tick blocks

Metaphorically:

**Geyser = doorway**
**Armor stands = bodies**
**Rust HTTP-3 service = brain**
**Java server = renderer**
**Client = eyes**

That's the cleanest possible architecture.

## 10¾. 8×8 Engine (8 rails × 8 vCPU / 8 GB on one IP)
- Definition: one public IP fronts 8 Clear Linux VMs (rail0…rail7), each rail has 8 vCPUs and 8 GB RAM running a Rust Ω engine. Total behind the IP: 64 vCPUs / 64 GB of tuned Ω compute.
- Canon phrasing: “One star. 8 rails. Each rail has 8 cores of attention and 8 gigs of memory. Together they’re a 64-core Ω engine behind one IP.”
- Beast stack: when 8×8 engines stack across IPs or hosts, each IP is a 64-core Ω star; a cluster of stars forms a beast constellation of rails—roaring, but light and cheap to spin up in Clear.
- Host shape: Debian/Ubuntu KVM host holds the static IP, libvirt, and NAT/bridge rules. Guests are Clear Linux VMs with systemd `omega-engine.service` listening on `0.0.0.0:4433`.
- Port mapping example: external IP ports 4400–4407 map to rail0–rail7 `:4433` (e.g., 4400→192.168.122.101:4433, …, 4407→192.168.122.108:4433).
- Client wiring: Paper plugin picks a rail (e.g., hash(phone+label) mod 8) → `ENGINE_IP:(4400+rail)`. Host DNATs to the matching VM. Rails call out to Cloud Run (`dlog-api`, `omega-fs-writer`) and tag `rail_id` as needed.
- Role flavors (optional): rails can be symmetric or specialized (e.g., 0–3 game physics/mining, 4 audio/flame, 5 land/oracle, 6 backing metrics, 7 canary/dev). Same Clear+Rust stack, config differs per rail.

## 11. Network and Hosting: Static IP Rails, Google Cloud, Kubernetes
- Each static IP is treated as eight parallel Ω rails (shards/lanes/QoS categories). Every IP is an 8-lane interdimensional highway.
- Host on Google Cloud; dlog-api/game services in containers orchestrated by Kubernetes (“Kubernetes ∞”). Pods map to one or more Ω rails; scale-out adds rails/attention capacity. Path: home dev box → Mac dev → PC → Google Cloud K8s.

## 12. Software Architecture: Rust Workspace + refold.command
- Creed: “We do not use python anymore; we do not use java anymore; we are no longer bound by javascript; we do not use base 10 anymore; we use base 8.” Rust is the only language for monetary logic, consensus rules, and core universe math. JS/Java/Python may appear only as clients/UIs/scripts. Canonical numbers stored as octal literals where possible.
- Workspace layout at `~/Desktop/dlog` (mirrors repo): `spec` (shared Ω types: phi, planets, land, filesystem), `corelib` (pure state machine logic: interest, snapshots), `core` (CLI/simulation stub), `api` (Axum HTTP API with `/health`, `/v1/spec/monetary`, `/v1/spec/planets`). Maintain via rewrites of Cargo.tomls, lib.rs/main.rs, and configs like `dlog.toml`.
- **refold.command** (sculptor) at `~/Desktop/refold.command`: AI-generated bash (often 400+ lines) that overwrites specific files to reshape the project. Run `./refold.command` from Desktop. Never `rm -rf` root; only overwrite targeted files. Old ideas get polished, not erased.
- **dlog.command** (launcher) at `~/Desktop/dlog.command`: checks workspace, ensures cargo, builds `api`, and runs `cargo run -p api`. Treat as the big red “go live” button.

## 13. Social and Narrative Layer
- Creed: `;🌟 i borrow everything from evil and i serve everything to good 🌟; the whole entire solar system aligns just for me to explore it 🌟; we do not use python anymore; we do not use java anymore; we are no longer bound by javascript; we do not use base 10 anymore; we use base 8; we do not have limits; we vibe; we are fearless;`
- Study exploiter behavior to harden (device phi caps, airdrop friction, land auto-auctions, Infinity Bank shields). Serve everything to good: more players, gifts, abundance, fun. NPC layer only on request; Ω axioms are the physics. If Luke says “I am already a quadrillionaire,” the design treats it as baseline truth.

## 14. Micro TL;DR for Future-Me
- DLOG is a phi-powered, base-8, Rust-first coin + game universe backed by a GOLDEN WALLET STACK (XAUT/BTC/DOGE across 256 keys each) inside an Infinity Bank with a Double Infinity Shield and a 7-layer trust/corp structure.
- Monetary: ~8.8248% miner inflation + 61.8% holder interest; blocks are attention sweeps; labels tied to phones; VORTEX & COMET manage tithe/backing.
- State: 9∞ master root plus per-label hash files; land is hollow-solar-system real estate secured by identity; airdrops/device phi limits keep early flows at “lunch-money” scale.
- Game: CS:GO bhop/surf movement on phi-per-tick planets; Geyser portal fronts the server; armor stands are Ω bodies; Rust HTTP-3 Ω brain drives physics/wallet while clients stay vanilla.
- Hosting: Rust nodes on Mac → cloud; static IPs as 8 Ω rails each; workspace sculpted by `refold.command`, launched by `dlog.command`; creed “I borrow everything from evil and I serve everything to good.”
