use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;

/// Incoming handshake payload from an HTTP-4 client.
#[derive(Debug, Clone, Deserialize)]
pub struct HandshakeRequest {
    pub client_id: String,
    #[serde(default)]
    pub capabilities: Vec<String>,
    #[serde(default)]
    pub requested_routes: Vec<String>,
}

/// Response issued once a session is registered.
#[derive(Debug, Clone, Serialize)]
pub struct HandshakeResponse {
    pub session_id: String,
    pub kernel_version: String,
    pub motd: String,
    pub router_epoch_ms: i64,
    pub granted_routes: Vec<RouteHint>,
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

/// A structured pointer to an Omega subsystem.
#[derive(Debug, Clone, Serialize)]
pub struct RouteHint {
    pub omega_path: String,
    pub target: String,
    pub confidence: f32,
}

#[derive(Debug, Clone)]
struct SessionInfo {
    client_id: String,
    capabilities: Vec<String>,
    established_ms: i64,
}

/// In-memory gateway placeholder. Later this becomes the QUIC/HTTP-4 kernel.
#[derive(Debug)]
pub struct OmegaGateway {
    id: String,
    boot_ms: i64,
    sessions: Mutex<HashMap<String, SessionInfo>>,
}

impl OmegaGateway {
    pub fn new() -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            boot_ms: now_ms(),
            sessions: Mutex::new(HashMap::new()),
        }
    }

    pub fn id(&self) -> &str {
        &self.id
    }

    pub fn boot_ms(&self) -> i64 {
        self.boot_ms
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
            },
        );
        drop(guard);

        HandshakeResponse {
            session_id,
            kernel_version: "omega-http4-edge@0.1.0".into(),
            motd: "Welcome to the Ω gateway — route via DNS frames and stay phi-synced.".into(),
            router_epoch_ms: self.boot_ms,
            granted_routes,
        }
    }

    /// Stub router: inspects the frame kind and whispers where it would flow.
    pub fn handle_frame(&self, frame: FrameEnvelope) -> FrameAck {
        let notes = self.validate_session(&frame.session_id);
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
}

fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}
