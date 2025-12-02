use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

const PHI_F32: f32 = 1.618_033_988_75_f32;
const INPUT_VELOCITY_SCALE: f32 = 0.08;
const INPUT_ASCENT_SCALE: f32 = 0.16;
const DEFAULT_WORLD_MAX_Y: f32 = 320.0;

/// Incoming handshake payload from an HTTP-4 client.
#[derive(Debug, Clone, Deserialize)]
pub struct HandshakeRequest {
    pub client_id: String,
    #[serde(default)]
    pub capabilities: Vec<String>,
    #[serde(default)]
    pub requested_routes: Vec<String>,
    #[serde(default)]
    pub phone: Option<String>,
    #[serde(default)]
    pub session_token: Option<String>,
}

/// Response issued once a session is registered.
#[derive(Debug, Clone, Serialize)]
pub struct HandshakeResponse {
    pub session_id: String,
    pub kernel_version: String,
    pub motd: String,
    pub router_epoch_ms: i64,
    pub granted_routes: Vec<RouteHint>,
    pub identity: Option<IdentityDescriptor>,
}

#[derive(Debug, Clone, Serialize)]
pub struct IdentityDescriptor {
    pub phone: String,
    pub label: String,
    pub display_name: String,
    pub presence_state: String,
}

/// High-level frame types supported by the Omega router.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum FrameKind {
    TickFrame,
    Query,
    Event,
    MineJob,
    MineResult,
    Dns,
    Audio,
    Game,
    Input,
}

/// Envelope around a binary HTTP-4 frame. The payload itself stays opaque (`serde_json::Value`)
/// until downstream subsystems bind to it.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FrameEnvelope {
    pub session_id: String,
    pub seq: u64,
    pub namespace: String,
    pub kind: FrameKind,
    #[serde(default)]
    pub payload: serde_json::Value,
}

/// Router response with DNS hints and tick metadata.
#[derive(Debug, Clone, Serialize)]
pub struct FrameAck {
    pub session_id: String,
    pub seq: u64,
    pub accepted: bool,
    pub next_tick_ms: i64,
    pub routed: Vec<RouteHint>,
    pub notes: Vec<String>,
}

/// Snapshot of the gateway for observability endpoints.
#[derive(Debug, Clone, Serialize)]
pub struct GatewayStatus {
    pub gateway_id: String,
    pub boot_ms: i64,
    pub session_count: usize,
    pub services: Vec<&'static str>,
}

/// A structured pointer to an Omega subsystem.
#[derive(Debug, Clone, Serialize)]
pub struct RouteHint {
    pub omega_path: String,
    pub target: String,
    pub confidence: f32,
}

#[derive(Debug, Clone)]
pub struct BridgeInputSnapshot {
    pub player_uuid: String,
    pub session_id: Option<String>,
    pub stand_id: Option<String>,
    pub device: Option<String>,
    pub profile: Option<String>,
    pub buttons: Vec<BridgeButtonSnapshot>,
    pub axes: Vec<BridgeAxisSnapshot>,
    pub timestamp_ms: Option<i64>,
}

#[derive(Debug, Clone)]
pub struct BridgeButtonSnapshot {
    pub action: String,
    pub state: ButtonState,
}

#[derive(Debug, Clone, Copy)]
pub enum ButtonState {
    Pressed,
    Released,
    Held,
}

#[derive(Debug, Clone)]
pub struct BridgeAxisSnapshot {
    pub action: String,
    pub x: f32,
    pub y: f32,
    pub mode: AxisMode,
}

#[derive(Debug, Clone, Copy)]
pub enum AxisMode {
    Relative,
    Absolute,
}

#[derive(Debug, Clone)]
pub struct BridgePositionSnapshot {
    pub player_uuid: String,
    pub session_id: Option<String>,
    pub stand_id: Option<String>,
    pub world: String,
    pub pos: Vec3f,
    pub velocity: Option<Vec3f>,
    pub rotation: Option<Rotation2d>,
}

#[derive(Debug, Clone, Copy)]
pub struct Vec3f {
    pub x: f32,
    pub y: f32,
    pub z: f32,
}

#[derive(Debug, Clone, Copy)]
pub struct Rotation2d {
    pub yaw: f32,
    pub pitch: f32,
}

#[derive(Debug, Clone, Serialize)]
#[serde(tag = "instruction", rename_all = "snake_case")]
pub enum BridgeInstruction {
    SetVelocity {
        stand_id: Option<String>,
        vx: f32,
        vy: f32,
        vz: f32,
    },
    SetPosition {
        stand_id: Option<String>,
        x: f32,
        y: f32,
        z: f32,
    },
    AlignRotation {
        stand_id: Option<String>,
        yaw: f32,
        pitch: f32,
    },
    Echo {
        stand_id: Option<String>,
        message: String,
    },
}

#[allow(dead_code)]
#[derive(Debug, Clone)]
struct SessionInfo {
    client_id: String,
    capabilities: Vec<String>,
    established_ms: i64,
    last_input_ms: i64,
}

/// In-memory gateway placeholder. Later this becomes the QUIC/HTTP-4 kernel.
#[derive(Debug)]
pub struct OmegaGateway {
    id: String,
    boot_ms: i64,
    sessions: Mutex<HashMap<String, SessionInfo>>,
    services: OmegaServices,
}

impl OmegaGateway {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            boot_ms: now_ms(),
            sessions: Mutex::new(HashMap::new()),
            services: OmegaServices::default(),
        }
    }

    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn boot_ms(&self) -> i64 {
        self.boot_ms
    }

    pub fn status(&self) -> GatewayStatus {
        let sessions = self.sessions.lock().expect("sessions mutex poisoned");
        GatewayStatus {
            gateway_id: self.id.clone(),
            boot_ms: self.boot_ms,
            session_count: sessions.len(),
            services: self.services.list(),
        }
    }

    /// Registers a session and emits route hints for the requested namespaces.
    pub fn handle_handshake(&self, req: HandshakeRequest) -> HandshakeResponse {
        let session_id = Uuid::new_v4().to_string();
        let granted_routes = if req.requested_routes.is_empty() {
            self.default_routes()
        } else {
            req.requested_routes
                .iter()
                .flat_map(|route| self.route_for_namespace(route, FrameKind::Dns))
                .collect()
        };

        let mut guard = self.sessions.lock().expect("sessions mutex poisoned");
        guard.insert(
            session_id.clone(),
            SessionInfo {
                client_id: req.client_id,
                capabilities: req.capabilities,
                established_ms: now_ms(),
                last_input_ms: now_ms(),
            },
        );
        drop(guard);

        HandshakeResponse {
            session_id,
            kernel_version: "omega-http4-edge@0.1.0".into(),
            motd: "Welcome to the Ω gateway — route via DNS frames and stay phi-synced.".into(),
            router_epoch_ms: self.boot_ms,
            granted_routes,
            identity: None,
        }
    }

    /// Stub router: inspects the frame kind and whispers where it would flow.
    pub fn handle_frame(&self, frame: FrameEnvelope) -> FrameAck {
        let mut notes = self.validate_session(&frame.session_id);
        if frame.kind == FrameKind::Input {
            self.bump_input_timestamp(&frame.session_id);
        }
        notes.extend(self.services.dispatch(&frame));
        let routed = self.route_for_namespace(&frame.namespace, frame.kind.clone());
        FrameAck {
            session_id: frame.session_id,
            seq: frame.seq,
            accepted: true,
            next_tick_ms: now_ms() + 8,
            routed,
            notes,
        }
    }

    fn validate_session(&self, session_id: &str) -> Vec<String> {
        let guard = self.sessions.lock().expect("sessions mutex poisoned");
        if guard.contains_key(session_id) {
            vec![format!("session:{session_id} ok")]
        } else {
            vec![format!(
                "session:{session_id} unknown — router will accept but should re-handshake"
            )]
        }
    }

    fn bump_input_timestamp(&self, session_id: &str) {
        let mut guard = self.sessions.lock().expect("sessions mutex poisoned");
        if let Some(info) = guard.get_mut(session_id) {
            info.last_input_ms = now_ms();
        }
    }

    fn default_routes(&self) -> Vec<RouteHint> {
        vec![
            RouteHint {
                omega_path: ";∞;dns;router;".into(),
                target: "omega.dns.router".into(),
                confidence: 0.99,
            },
            RouteHint {
                omega_path: ";∞;bank;infinity;".into(),
                target: "omega.bank.infinity".into(),
                confidence: 0.92,
            },
            RouteHint {
                omega_path: ";∞;speaker;engine;".into(),
                target: "omega.audio.stack".into(),
                confidence: 0.9,
            },
        ]
    }

    fn route_for_namespace(&self, namespace: &str, kind: FrameKind) -> Vec<RouteHint> {
        let cleaned = namespace.trim_matches(';');
        let mut hints = Vec::new();
        let kind_hint = match kind {
            FrameKind::TickFrame => ("tick", "omega.sim.kernel"),
            FrameKind::Query => ("query", "omega.search"),
            FrameKind::Event => ("event", "omega.event.bus"),
            FrameKind::MineJob => ("mine_job", "omega.mining.dispatch"),
            FrameKind::MineResult => ("mine_result", "omega.mining.result"),
            FrameKind::Dns => ("dns", "omega.dns.router"),
            FrameKind::Audio => ("audio", "omega.audio.stack"),
            FrameKind::Game => ("game", "omega.game.engine"),
            FrameKind::Input => ("input", "omega.input.buffer"),
        };

        hints.push(RouteHint {
            omega_path: format!(";∞;{cleaned};{kind_key};", kind_key = kind_hint.0),
            target: kind_hint.1.into(),
            confidence: 0.88,
        });

        // Secondary route to illustrate multi-hop DNS.
        if cleaned.contains("bank") || cleaned.contains("vortex") {
            hints.push(RouteHint {
                omega_path: ";∞;bank;gravity;router;".into(),
                target: "omega.bank.gravity".into(),
                confidence: 0.77,
            });
        }

        hints
    }

    pub fn process_bridge_input(&self, snapshot: BridgeInputSnapshot) -> Vec<BridgeInstruction> {
        if let Some(session_id) = snapshot.session_id.as_deref() {
            self.bump_input_timestamp(session_id);
        }
        let mut instructions = Vec::new();

        let profile_scale = match snapshot.profile.as_deref() {
            Some(name) if name.eq_ignore_ascii_case("surf") => 1.35,
            Some(name) if name.eq_ignore_ascii_case("bhop") => 1.2,
            _ => 1.0,
        };
        let device_scale = match snapshot.device.as_deref() {
            Some("touch") => 0.7,
            Some("gamepad") => 0.9,
            _ => 1.0,
        };
        let velocity_scale = PHI_F32 * INPUT_VELOCITY_SCALE * profile_scale * device_scale;

        if let Some(axis) = snapshot.axes.iter().find(|axis| {
            axis.action.eq_ignore_ascii_case("move")
                || axis.action.eq_ignore_ascii_case("move_plane")
        }) {
            match axis.mode {
                AxisMode::Relative => instructions.push(BridgeInstruction::SetVelocity {
                    stand_id: snapshot.stand_id.clone(),
                    vx: axis.x * velocity_scale,
                    vy: 0.0,
                    vz: axis.y * velocity_scale,
                }),
                AxisMode::Absolute => instructions.push(BridgeInstruction::SetPosition {
                    stand_id: snapshot.stand_id.clone(),
                    x: axis.x,
                    y: snapshot.timestamp_ms.unwrap_or_default() as f32 % 32.0,
                    z: axis.y,
                }),
            }
        }

        if let Some(axis) = snapshot
            .axes
            .iter()
            .find(|axis| axis.action.eq_ignore_ascii_case("look"))
        {
            instructions.push(BridgeInstruction::AlignRotation {
                stand_id: snapshot.stand_id.clone(),
                yaw: axis.x * 4.0,
                pitch: axis.y * 4.0,
            });
        }

        let jump_pressed = snapshot.buttons.iter().any(|button| {
            button.action.eq_ignore_ascii_case("jump")
                && matches!(button.state, ButtonState::Pressed | ButtonState::Held)
        });
        if jump_pressed {
            instructions.push(BridgeInstruction::SetVelocity {
                stand_id: snapshot.stand_id.clone(),
                vx: 0.0,
                vy: PHI_F32 * INPUT_ASCENT_SCALE,
                vz: 0.0,
            });
        }

        if instructions.is_empty() {
            instructions.push(BridgeInstruction::Echo {
                stand_id: snapshot.stand_id,
                message: format!(
                    "input captured for {} at {}",
                    snapshot.player_uuid,
                    snapshot.timestamp_ms.unwrap_or_default()
                ),
            });
        }

        instructions
    }

    pub fn process_bridge_position(
        &self,
        snapshot: BridgePositionSnapshot,
    ) -> Vec<BridgeInstruction> {
        if let Some(session_id) = snapshot.session_id.as_deref() {
            self.bump_input_timestamp(session_id);
        }

        let (min_y, max_y) = bounds_for_world(&snapshot.world);
        let clamped_y = snapshot.pos.y.clamp(min_y, max_y);
        let mut instructions = vec![BridgeInstruction::SetPosition {
            stand_id: snapshot.stand_id.clone(),
            x: snapshot.pos.x,
            y: clamped_y,
            z: snapshot.pos.z,
        }];

        if let Some(velocity) = snapshot.velocity {
            instructions.push(BridgeInstruction::SetVelocity {
                stand_id: snapshot.stand_id.clone(),
                vx: velocity.x,
                vy: velocity.y,
                vz: velocity.z,
            });
        }

        if let Some(rotation) = snapshot.rotation {
            instructions.push(BridgeInstruction::AlignRotation {
                stand_id: snapshot.stand_id,
                yaw: rotation.yaw,
                pitch: rotation.pitch,
            });
        }

        instructions.push(BridgeInstruction::Echo {
            stand_id: None,
            message: format!(
                "position sync for {} in {}",
                snapshot.player_uuid, snapshot.world
            ),
        });

        instructions
    }
}

fn bounds_for_world(world: &str) -> (f32, f32) {
    match world {
        "moon_shell" | "moon_core" => (0.0, 160.0),
        "mars_shell" | "mars_core" => (0.0, 210.0),
        "sun_shell" | "sun_core" => (32.0, 400.0),
        "earth_core" => (0.0, 128.0),
        _ => (0.0, DEFAULT_WORLD_MAX_Y),
    }
}

/// Aggregates all Ω services that sit behind the HTTP-4 router.
#[derive(Debug, Default)]
struct OmegaServices {
    dns: DnsRouter,
    banking: InfinityBank,
    mining: MiningDispatch,
    speaker: SpeakerEngine,
    game: GameEngine,
}

impl OmegaServices {
    fn list(&self) -> Vec<&'static str> {
        vec![
            "omega.dns.router",
            "omega.bank.infinity",
            "omega.mining.dispatch",
            "omega.audio.stack",
            "omega.game.engine",
        ]
    }

    fn dispatch(&self, frame: &FrameEnvelope) -> Vec<String> {
        let mut notes = Vec::new();
        match frame.kind {
            FrameKind::Dns => notes.push(self.dns.resolve(&frame.namespace)),
            FrameKind::MineJob | FrameKind::MineResult => {
                notes.push(self.mining.handle(frame));
            }
            FrameKind::Audio => notes.push(self.speaker.handle(frame)),
            FrameKind::Game | FrameKind::TickFrame => notes.push(self.game.handle(frame)),
            FrameKind::Query | FrameKind::Event => notes.push(self.banking.handle(frame)),
            FrameKind::Input => notes.push("input frame buffered".into()),
        }
        notes
    }
}

#[derive(Debug)]
struct DnsRouter {
    records: HashMap<String, DnsRecord>,
}

#[derive(Debug, Clone)]
struct DnsRecord {
    omega_path: String,
    target: String,
    description: &'static str,
}

impl Default for DnsRouter {
    fn default() -> Self {
        let mut records = HashMap::new();
        for record in [
            DnsRecord {
                omega_path: ";∞;dns;router;".into(),
                target: "omega.dns.router".into(),
                description: "Omega path router",
            },
            DnsRecord {
                omega_path: ";∞;bank;infinity;".into(),
                target: "omega.bank.infinity".into(),
                description: "Gravity-backed Infinity bank",
            },
            DnsRecord {
                omega_path: ";∞;bank;gravity;router;".into(),
                target: "omega.bank.gravity".into(),
                description: "VORTEX/COMET gravity router",
            },
            DnsRecord {
                omega_path: ";∞;speaker;engine;".into(),
                target: "omega.audio.stack".into(),
                description: "Omega speaker engine",
            },
            DnsRecord {
                omega_path: ";∞;game;engine;".into(),
                target: "omega.game.engine".into(),
                description: "Simulation + gameplay kernel",
            },
            DnsRecord {
                omega_path: ";∞;mining;dispatch;".into(),
                target: "omega.mining.dispatch".into(),
                description: "Hash dispatch + silicon rails",
            },
            DnsRecord {
                omega_path: ";∞;mining;result;".into(),
                target: "omega.mining.result".into(),
                description: "Mining result verifier",
            },
        ] {
            records.insert(Self::canonical_key(&record.omega_path), record);
        }

        Self { records }
    }
}

impl DnsRouter {
    fn resolve(&self, namespace: &str) -> String {
        let key = Self::canonical_key(namespace);
        if let Some(record) = self.records.get(&key) {
            return format!(
                "dns::{key} → {target} ({desc})",
                target = record.target,
                desc = record.description
            );
        }

        for fallback in Self::fallback_keys(&key) {
            if let Some(record) = self.records.get(&fallback) {
                return format!(
                    "dns::{key} → {target} (via {path})",
                    target = record.target,
                    path = record.omega_path
                );
            }
        }

        format!("dns::{key} → (unmapped) request router-registration")
    }

    fn canonical_key(namespace: &str) -> String {
        namespace
            .split(';')
            .filter(|s| !s.is_empty())
            .map(|segment| segment.to_ascii_lowercase())
            .collect::<Vec<_>>()
            .join(".")
    }

    fn fallback_keys(key: &str) -> Vec<String> {
        let mut parts: Vec<&str> = key.split('.').collect();
        let mut fallbacks = Vec::new();
        while parts.len() > 1 {
            parts.pop();
            fallbacks.push(parts.join("."));
        }
        fallbacks
    }
}

#[derive(Debug)]
struct InfinityBank {
    ledger: Mutex<HashMap<String, u128>>,
    #[allow(dead_code)]
    interest_apy_bps: u32,
    last_tick_ms: Mutex<i64>,
    per_tick_factor_ppm: u64,
}

impl Default for InfinityBank {
    fn default() -> Self {
        let mut ledger = HashMap::new();
        ledger.insert(";9132077554;comet;".into(), 1_000_000);
        ledger.insert(";9132077554;vortex1;".into(), 5_000_000);
        ledger.insert(";9132077554;fun;".into(), 80_000);
        Self {
            ledger: Mutex::new(ledger),
            interest_apy_bps: 6180,
            last_tick_ms: Mutex::new(now_ms()),
            per_tick_factor_ppm: Self::phi_tick_factor_ppm(),
        }
    }
}

impl InfinityBank {
    fn phi_tick_factor_ppm() -> u64 {
        1_000_020
    }

    fn accrue_interest(&self) {
        let now = now_ms();
        let mut last = self
            .last_tick_ms
            .lock()
            .expect("bank last_tick mutex poisoned");

        if now <= *last {
            return;
        }

        let ticks = ((now - *last) / 8).max(1) as u64;
        let factor = self.per_tick_factor_ppm as u128;
        let mut ledger = self.ledger.lock().expect("ledger mutex poisoned");

        for balance in ledger.values_mut() {
            for _ in 0..ticks {
                *balance = (*balance * factor) / 1_000_000;
            }
        }

        *last = now;
    }

    fn handle(&self, frame: &FrameEnvelope) -> String {
        self.accrue_interest();
        match frame
            .payload
            .get("kind")
            .and_then(Value::as_str)
            .unwrap_or("unknown")
        {
            "balance_query" => {
                let label = frame
                    .payload
                    .get("label")
                    .and_then(Value::as_str)
                    .unwrap_or(";<unknown>;");
                let balance = self.balance_of(label);
                format!("bank::balance {label} = {balance}")
            }
            "transfer" => self.handle_transfer(&frame.payload),
            _ => format!(
                "bank::{} routed (seq {})",
                frame.namespace.trim_matches(';'),
                frame.seq
            ),
        }
    }

    fn balance_of(&self, label: &str) -> u128 {
        let ledger = self.ledger.lock().expect("ledger mutex poisoned");
        ledger.get(label).copied().unwrap_or_default()
    }

    fn handle_transfer(&self, payload: &Value) -> String {
        let from = payload
            .get("from")
            .and_then(Value::as_str)
            .unwrap_or(";<missing-from>;");
        let to = payload
            .get("to")
            .and_then(Value::as_str)
            .unwrap_or(";<missing-to>;");
        let amount = payload.get("amount").and_then(Value::as_u64).unwrap_or(0) as u128;

        if amount == 0 {
            return "bank::transfer rejected (amount=0)".into();
        }

        let mut ledger = self.ledger.lock().expect("ledger mutex poisoned");
        let from_balance = ledger.get(from).copied().unwrap_or_default();
        if from_balance < amount {
            return format!(
                "bank::transfer rejected ({from} insufficient: {from_balance} < {amount})"
            );
        }

        let to_balance = ledger.get(to).copied().unwrap_or_default();
        ledger.insert(from.into(), from_balance - amount);
        ledger.insert(to.into(), to_balance + amount);

        format!("bank::transfer {amount} {from} → {to} ok")
    }
}

#[derive(Debug, Default)]
struct MiningDispatch;

impl MiningDispatch {
    fn handle(&self, frame: &FrameEnvelope) -> String {
        match frame.kind {
            FrameKind::MineJob => format!("mining dispatched job seq {}", frame.seq),
            FrameKind::MineResult => format!("mining verified result seq {}", frame.seq),
            _ => "mining received unexpected frame".into(),
        }
    }
}

#[derive(Debug, Default)]
struct SpeakerEngine;

impl SpeakerEngine {
    fn handle(&self, frame: &FrameEnvelope) -> String {
        format!(
            "speaker scheduled audio burst for namespace {}",
            frame.namespace
        )
    }
}

#[derive(Debug, Default)]
struct GameEngine;

impl GameEngine {
    fn handle(&self, frame: &FrameEnvelope) -> String {
        format!(
            "game tick routed for {} (seq {})",
            frame.namespace, frame.seq
        )
    }
}

fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}
