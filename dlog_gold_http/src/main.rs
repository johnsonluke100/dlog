mod omega;

use axum::{
    body::Body,
    extract::{Query, State},
    http::{Request, StatusCode, Uri},
    middleware::{self, Next},
    response::{Html, IntoResponse, Redirect, Response},
    routing::{get, post},
    Json, Router,
};
use spec::SkyShowConfig;
use omega::{
    AxisMode, BridgeInputSnapshot, BridgeInstruction, BridgePositionSnapshot, FrameAck,
    FrameEnvelope, GatewayStatus, HandshakeRequest, HandshakeResponse, IdentityDescriptor,
    OmegaGateway,
};
use dlog_sky::SkyTimeline;
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    env,
    net::SocketAddr,
    sync::{Arc, Mutex},
};
use tokio::net::TcpListener;
use tracing::{error, info, warn};

#[derive(Clone)]
struct AppState {
    gateway: Arc<OmegaGateway>,
    presence: Client,
    presence_base: String,
    phone_auth: Arc<PhoneAuth>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
struct RootResponse<'a> {
    status: &'a str,
    motd: &'a str,
    golden_wallet: GoldenWalletStack<'a>,
    omega_layers: Vec<Layer<'a>>,
    canon_links: CanonLinks<'a>,
    commands: Vec<&'a str>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
struct GoldenWalletStack<'a> {
    title: &'a str,
    mantra: &'a str,
    assets: Vec<&'a str>,
    decree: &'a str,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
struct Layer<'a> {
    name: &'a str,
    summary: &'a str,
    highlights: Vec<&'a str>,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
struct CanonLinks<'a> {
    repo: &'a str,
    airdrop: &'a str,
    soundtrack: &'a str,
}

#[derive(Debug, Serialize)]
struct HealthResponse {
    status: &'static str,
    gateway_id: String,
    boot_ms: i64,
}

#[derive(Debug, Serialize, Clone)]
struct SkyTimelineResponse {
    total_duration_ticks: u64,
    show: SkyShowConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct MojangPresencePayload {
    gamer_tag: String,
    mojang_uuid: String,
    phone: String,
    label: String,
    display_name: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WebPresencePayload {
    phone: String,
    label: String,
    session_token: String,
    display_name: String,
}

#[derive(Debug, Clone, Deserialize)]
struct PhoneStartRequest {
    phone: String,
    #[serde(default)]
    label: Option<String>,
    #[serde(default)]
    display_name: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
struct PhoneStartResponse {
    session_token: String,
    expires_in_ms: i64,
    providers: Vec<&'static str>,
    biometric_required: bool,
    instructions: &'static str,
}

#[derive(Debug, Clone, Deserialize)]
struct PhoneConfirmRequest {
    session_token: String,
    biometric_signature: String,
}

#[derive(Debug, Clone, Serialize)]
struct PhoneConfirmResponse {
    status: &'static str,
    phone: Option<String>,
    verified: bool,
}

#[derive(Debug, Clone)]
struct PhoneAuthIdentity {
    phone: String,
    label: String,
    display_name: String,
    session_token: String,
}

#[derive(Debug, Deserialize)]
struct BridgeInputPayload {
    player_uuid: String,
    session_id: Option<String>,
    stand_id: Option<String>,
    device: Option<String>,
    profile: Option<String>,
    #[serde(default)]
    buttons: Vec<ButtonEvent>,
    #[serde(default)]
    axes: Vec<AxisEvent>,
    timestamp_ms: Option<i64>,
}

#[derive(Debug, Deserialize)]
struct ButtonEvent {
    action: String,
    state: ButtonStatePayload,
}

#[derive(Debug, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
enum ButtonStatePayload {
    Pressed,
    #[default]
    Released,
    Held,
}

#[derive(Debug, Deserialize)]
struct AxisEvent {
    action: String,
    x: f32,
    y: f32,
    mode: Option<AxisModePayload>,
}

#[derive(Debug, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
enum AxisModePayload {
    #[default]
    Relative,
    Absolute,
}

#[derive(Debug, Deserialize)]
struct BridgePositionPayload {
    player_uuid: String,
    session_id: Option<String>,
    stand_id: Option<String>,
    world: String,
    position: Vec3Payload,
    velocity: Option<Vec3Payload>,
    rotation: Option<RotationPayload>,
}

#[derive(Debug, Deserialize)]
struct Vec3Payload {
    x: f32,
    y: f32,
    z: f32,
}

#[derive(Debug, Deserialize)]
struct RotationPayload {
    yaw: f32,
    pitch: f32,
}

#[derive(Debug, Serialize)]
struct BridgeResponse {
    status: &'static str,
    instructions: Vec<BridgeInstruction>,
}

impl BridgeInputPayload {
    fn into_snapshot(self) -> BridgeInputSnapshot {
        BridgeInputSnapshot {
            player_uuid: self.player_uuid,
            session_id: self.session_id,
            stand_id: self.stand_id,
            device: self.device,
            profile: self.profile,
            buttons: self
                .buttons
                .into_iter()
                .map(|b| b.into_button_snapshot())
                .collect(),
            axes: self
                .axes
                .into_iter()
                .map(|a| a.into_axis_snapshot())
                .collect(),
            timestamp_ms: self.timestamp_ms,
        }
    }
}

impl ButtonEvent {
    fn into_button_snapshot(self) -> omega::BridgeButtonSnapshot {
        omega::BridgeButtonSnapshot {
            action: self.action,
            state: match self.state {
                ButtonStatePayload::Pressed => omega::ButtonState::Pressed,
                ButtonStatePayload::Released => omega::ButtonState::Released,
                ButtonStatePayload::Held => omega::ButtonState::Held,
            },
        }
    }
}

impl AxisEvent {
    fn into_axis_snapshot(self) -> omega::BridgeAxisSnapshot {
        omega::BridgeAxisSnapshot {
            action: self.action,
            x: self.x,
            y: self.y,
            mode: match self.mode.unwrap_or_default() {
                AxisModePayload::Relative => AxisMode::Relative,
                AxisModePayload::Absolute => AxisMode::Absolute,
            },
        }
    }
}

impl BridgePositionPayload {
    fn into_snapshot(self) -> BridgePositionSnapshot {
        BridgePositionSnapshot {
            player_uuid: self.player_uuid,
            session_id: self.session_id,
            stand_id: self.stand_id,
            world: self.world,
            pos: self.position.into_vec3(),
            velocity: self.velocity.map(|v| v.into_vec3()),
            rotation: self.rotation.map(|r| r.into_rotation()),
        }
    }
}

impl Vec3Payload {
    fn into_vec3(self) -> omega::Vec3f {
        omega::Vec3f {
            x: self.x,
            y: self.y,
            z: self.z,
        }
    }
}

impl RotationPayload {
    fn into_rotation(self) -> omega::Rotation2d {
        omega::Rotation2d {
            yaw: self.yaw,
            pitch: self.pitch,
        }
    }
}

const HOST_REDIRECTS: &[(&str, &str)] = &[
    ("pool.dlog.gold", "minepool.gold"),
    ("www.pool.dlog.gold", "minepool.gold"),
    ("locks.dlog.gold", "locks.gold"),
    ("www.locks.dlog.gold", "locks.gold"),
];

const SIGNUP_FRAMES: [&str; 4] = [
    ";signup;frame=omega_shell;Deploy;the;GOLDEN;WALLET;STACK;protect;the;infinity;bank;",
    ";signup;frame=phone_ignition;POST;/auth/phone/start;receive;session_token;Apple/Google;biometrics;required;",
    ";signup;frame=biometric_lock;POST;/auth/phone/confirm;send;session_token;biometric_signature;phone=identity;",
    ";signup;frame=http4_bridge;set;DLOG_PHONE/DLOG_LABEL;run;dlog_http4_client;handshake;tick;mine;",
];

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_target(false)
        .with_level(true)
        .init();

    // Cloud Run injects PORT; default to 8080 for local runs
    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);

    let presence_base =
        env::var("PRESENCE_BASE_URL").unwrap_or_else(|_| "http://127.0.0.1:4000".to_string());

    let state = AppState {
        gateway: Arc::new(OmegaGateway::new()),
        presence: Client::new(),
        presence_base,
        phone_auth: Arc::new(PhoneAuth::default()),
    };

    let app = Router::new()
        .route("/", get(root))
        .route("/signup", get(signup_page))
        .route("/signup/frame", get(signup_frame))
        .route("/signup/qr", get(signup_qr))
        .route("/health", get(health))
        .route("/sky/timeline/default", get(sky_timeline_default))
        .route("/omega/status", get(status))
        .route("/omega/handshake", post(handshake))
        .route("/omega/frame", post(frame))
        .route("/omega/bridge/input", post(bridge_input))
        .route("/omega/bridge/position", post(bridge_position))
        .route("/identity/mojang", post(identity_mojang))
        .route("/identity/web", post(identity_web))
        .route("/auth/phone/start", post(auth_phone_start))
        .route("/auth/phone/confirm", post(auth_phone_confirm))
        .layer(middleware::from_fn(host_redirect))
        .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    info!("dlog.gold Ω-edge listening on http://{addr}");

    let listener = TcpListener::bind(addr)
        .await
        .expect("failed to bind TCP listener");

    if let Err(err) = axum::serve(listener, app).await {
        error!("server error: {err}");
    }
}

async fn root() -> Html<String> {
    let html = r#"<!doctype html>
<html lang=\"en\">
<head>
  <meta charset=\"utf-8\" />
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
  <title>dlog.gold · Minecraft</title>
  <style>
    body { font-family: sans-serif; background: #05060a; color: #e2e8f0; margin: 0; padding: 24px; }
    .card { max-width: 640px; margin: 0 auto; background: #0b0f1a; border: 1px solid #1f2937; border-radius: 12px; padding: 20px 24px; box-shadow: 0 8px 30px rgba(0,0,0,0.35); }
    h1 { margin-top: 0; }
    code { background: #111827; padding: 2px 6px; border-radius: 6px; color: #93c5fd; }
    ul { padding-left: 18px; }
    a { color: #93c5fd; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>
  <div class=\"card\">
    <h1>Welcome to dlog.gold</h1>
    <p>Join the Minecraft network:</p>
    <ul>
      <li><strong>Java:</strong> <code>dlog.gold</code> (port 25565)</li>
      <li><strong>Bedrock:</strong> <code>dlog.gold</code> (port 19132)</li>
    </ul>
    <p>APIs:</p>
    <ul>
      <li><a href=\"/sky/timeline/default\">/sky/timeline/default</a> – default sky show timeline</li>
      <li><a href=\"/health\">/health</a> – health check</li>
      <li><a href=\"/omega/status\">/omega/status</a> – omega gateway status</li>
    </ul>
    <p>Have fun. ✨</p>
  </div>
</body>
</html>"#;
    Html(html.to_string())
}

async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    Json(HealthResponse {
        status: "ok",
        gateway_id: state.gateway.id().to_string(),
        boot_ms: state.gateway.boot_ms(),
    })
}

async fn sky_timeline_default() -> Json<SkyTimelineResponse> {
    let timeline = SkyTimeline::default_eight();
    Json(SkyTimelineResponse {
        total_duration_ticks: timeline.total_duration_ticks(),
        show: timeline.show().clone(),
    })
}

async fn handshake(
    State(state): State<AppState>,
    Json(payload): Json<HandshakeRequest>,
) -> Result<Json<HandshakeResponse>, StatusCode> {
    let phone = payload
        .phone
        .as_deref()
        .ok_or(StatusCode::UNAUTHORIZED)?;
    let token = payload
        .session_token
        .as_deref()
        .ok_or(StatusCode::UNAUTHORIZED)?;
    let identity = state
        .phone_auth
        .verified_identity(token, phone)
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let mut response = state.gateway.handle_handshake(payload);
    response.identity = Some(identity);
    Ok(Json(response))
}

async fn frame(
    State(state): State<AppState>,
    Json(payload): Json<FrameEnvelope>,
) -> Json<FrameAck> {
    let response = state.gateway.handle_frame(payload);
    Json(response)
}

async fn status(State(state): State<AppState>) -> Json<GatewayStatus> {
    Json(state.gateway.status())
}

async fn identity_mojang(
    State(state): State<AppState>,
    Json(payload): Json<MojangPresencePayload>,
) -> StatusCode {
    let url = format!("{}/presence/mojang", state.presence_base);
    match state.presence.post(url).json(&payload).send().await {
        Ok(resp) if resp.status().is_success() => StatusCode::NO_CONTENT,
        Ok(resp) => StatusCode::from_u16(resp.status().as_u16()).unwrap_or(StatusCode::BAD_GATEWAY),
        Err(_) => StatusCode::BAD_GATEWAY,
    }
}

async fn identity_web(
    State(state): State<AppState>,
    Json(payload): Json<WebPresencePayload>,
) -> StatusCode {
    let url = format!("{}/presence/web", state.presence_base);
    match state.presence.post(url).json(&payload).send().await {
        Ok(resp) if resp.status().is_success() => StatusCode::NO_CONTENT,
        Ok(resp) => StatusCode::from_u16(resp.status().as_u16()).unwrap_or(StatusCode::BAD_GATEWAY),
        Err(_) => StatusCode::BAD_GATEWAY,
    }
}

async fn bridge_input(
    State(state): State<AppState>,
    Json(payload): Json<BridgeInputPayload>,
) -> Json<BridgeResponse> {
    let snapshot = payload.into_snapshot();
    let instructions = state.gateway.process_bridge_input(snapshot);
    Json(BridgeResponse {
        status: "ok",
        instructions,
    })
}

async fn bridge_position(
    State(state): State<AppState>,
    Json(payload): Json<BridgePositionPayload>,
) -> Json<BridgeResponse> {
    let snapshot = payload.into_snapshot();
    let instructions = state.gateway.process_bridge_position(snapshot);
    Json(BridgeResponse {
        status: "ok",
        instructions,
    })
}

async fn auth_phone_start(
    State(state): State<AppState>,
    Json(payload): Json<PhoneStartRequest>,
) -> Json<PhoneStartResponse> {
    let phone = payload.phone.trim().to_string();
    let label = payload
        .label
        .unwrap_or_else(|| "comet".to_string());
    let display_name = payload
        .display_name
        .unwrap_or_else(|| format!("Ω {}", phone));

    let session = state
        .phone_auth
        .start_session(phone, label, display_name, vec!["google", "apple"]);

    Json(PhoneStartResponse {
        session_token: session.token,
        expires_in_ms: session.expires_at_ms,
        providers: session.providers,
        biometric_required: true,
        instructions:
            "Tap Apple ID or Google, confirm device biometrics, then call /auth/phone/confirm.",
    })
}

async fn auth_phone_confirm(
    State(state): State<AppState>,
    Json(payload): Json<PhoneConfirmRequest>,
) -> (StatusCode, Json<PhoneConfirmResponse>) {
    match state
        .phone_auth
        .confirm_session(&payload.session_token, &payload.biometric_signature)
    {
        Some(identity) => {
            if let Err(err) = register_presence(&state, &identity).await {
                warn!("presence registration failed: {err}");
            }

            (
                StatusCode::OK,
                Json(PhoneConfirmResponse {
                    status: "verified",
                    phone: Some(identity.phone),
                    verified: true,
                }),
            )
        }
        None => (
            StatusCode::UNAUTHORIZED,
            Json(PhoneConfirmResponse {
                status: "invalid_or_expired",
                phone: None,
                verified: false,
            }),
        ),
    }
}

async fn register_presence(
    state: &AppState,
    identity: &PhoneAuthIdentity,
) -> Result<(), reqwest::Error> {
    let payload = WebPresencePayload {
        phone: identity.phone.clone(),
        label: identity.label.clone(),
        session_token: identity.session_token.clone(),
        display_name: identity.display_name.clone(),
    };

    state
        .presence
        .post(format!("{}/presence/web", state.presence_base))
        .json(&payload)
        .send()
        .await?
        .error_for_status()?;

    Ok(())
}

#[allow(dead_code)]
#[derive(Deserialize)]
struct PresenceLookupResponse {
    record: Option<PresenceRecordPayload>,
}

#[allow(dead_code)]
#[derive(Deserialize)]
struct PresenceRecordPayload {
    phone: String,
    label: String,
    display_name: String,
    state: PresenceStatePayload,
}

#[allow(dead_code)]
#[derive(Deserialize, Clone)]
#[serde(rename_all = "snake_case")]
enum PresenceStatePayload {
    Online,
    Idle,
    Offline,
}

#[allow(dead_code)]
async fn lookup_presence(state: &AppState, phone: &str) -> Option<IdentityDescriptor> {
    let url = format!("{}/presence/{}", state.presence_base, phone);
    let resp = state.presence.get(url).send().await.ok()?;
    let body = resp.json::<PresenceLookupResponse>().await.ok()?;
    let record = body.record?;
    let presence_state = match record.state {
        PresenceStatePayload::Online => "online",
        PresenceStatePayload::Idle => "idle",
        PresenceStatePayload::Offline => "offline",
    };
    Some(IdentityDescriptor {
        phone: record.phone,
        label: record.label,
        display_name: record.display_name,
        presence_state: presence_state.into(),
    })
}
async fn host_redirect(req: Request<Body>, next: Next) -> Response {
    if let Some(host) = req
        .headers()
        .get("host")
        .and_then(|value| value.to_str().ok())
    {
        if let Some((_, target_host)) = HOST_REDIRECTS
            .iter()
            .find(|(legacy, _)| legacy.eq_ignore_ascii_case(host))
        {
            let location = build_redirect_target(req.uri(), target_host);
            return Redirect::permanent(&location).into_response();
        }
    }

    next.run(req).await
}

fn build_redirect_target(uri: &Uri, host: &str) -> String {
    let mut location = format!("https://{host}{}", uri.path());
    if let Some(query) = uri.query() {
        location.push('?');
        location.push_str(query);
    }
    location
}

async fn signup_page() -> Response {
    let mut body = String::new();
    for frame in SIGNUP_FRAMES.iter() {
        body.push_str(frame);
        body.push('\n');
    }

    Response::builder()
        .header("content-type", "text/plain; charset=utf-8")
        .header("x-omega-loop", "true")
        .body(Body::from(body))
        .expect("signup response")
}

#[derive(Debug, Deserialize)]
struct FrameCursor {
    cursor: Option<usize>,
}

async fn signup_frame(Query(cursor): Query<FrameCursor>) -> Response {
    let total = SIGNUP_FRAMES.len().max(1);
    let idx = cursor.cursor.unwrap_or(0) % total;
    let next = (idx + 1) % total;
    let frame = SIGNUP_FRAMES[idx];

    Response::builder()
        .header("content-type", "text/plain; charset=utf-8")
        .header("x-loop-cursor", idx.to_string())
        .header("x-next-cursor", next.to_string())
        .header("x-loop-total", total.to_string())
        .header("x-loop-idle-ms", "10000")
        .body(Body::from(frame))
        .expect("signup frame response")
}

#[derive(Debug, Deserialize)]
struct QrParams {
    u: Option<String>,
}

async fn signup_qr(Query(params): Query<QrParams>) -> Response {
    // Allow override via ?u=<url>, otherwise default to /signup.
    let target = params.u.unwrap_or_else(|| {
        std::env::var("OMEGA_SIGNUP_URL")
            .ok()
            .filter(|v| !v.is_empty())
            .unwrap_or_else(|| "https://dlog.gold/signup".to_string())
    });

    let encoded: String = url::form_urlencoded::byte_serialize(target.as_bytes()).collect();
    let qr_src = format!(
        "https://chart.googleapis.com/chart?chs=240x240&cht=qr&chld=L|0&chl={}",
        encoded
    );

    let html = format!(
        r#"<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Scan to open dlog.gold</title>
  <style>
    body {{ background:#05060a; color:#e2e8f0; display:flex; align-items:center; justify-content:center; height:100vh; margin:0; font-family: 'SF Mono', monospace; }}
    .card {{ text-align:center; padding:24px; border-radius:12px; background:#0b0f1a; border:1px solid #1f2937; box-shadow:0 12px 40px rgba(0,0,0,0.4); }}
    img {{ width:240px; height:240px; }}
    p {{ margin:12px 0 0; font-size:14px; color:#94a3b8; }}
    a {{ color:#93c5fd; text-decoration:none; }}
  </style>
</head>
<body>
  <div class="card">
    <img src="{qr_src}" alt="QR to {target}" />
    <p>Scan to open<br><a href="{target}">{target}</a></p>
  </div>
</body>
</html>"#
    );

    Response::builder()
        .header("content-type", "text/html; charset=utf-8")
        .header("cache-control", "no-store")
        .body(Body::from(html))
        .expect("qr response")
}

#[derive(Debug, Default)]
struct PhoneAuth {
    sessions: Mutex<HashMap<String, PhoneAuthSession>>,
}

#[derive(Debug, Clone)]
struct PhoneAuthSession {
    token: String,
    phone: String,
    label: String,
    display_name: String,
    expires_at_ms: i64,
    verified: bool,
    providers: Vec<&'static str>,
}

impl PhoneAuth {
    fn start_session(
        &self,
        phone: String,
        label: String,
        display_name: String,
        providers: Vec<&'static str>,
    ) -> PhoneAuthSession {
        let token = uuid::Uuid::new_v4().to_string();
        let session = PhoneAuthSession {
            token: token.clone(),
            phone,
            label,
            display_name,
            expires_at_ms: epoch_ms() + 5 * 60 * 1000,
            verified: false,
            providers,
        };
        self.sessions
            .lock()
            .expect("phone auth lock")
            .insert(token.clone(), session.clone());
        session
    }

    fn confirm_session(
        &self,
        token: &str,
        biometric_signature: &str,
    ) -> Option<PhoneAuthIdentity> {
        if biometric_signature.trim().is_empty() {
            return None;
        }
        let mut guard = self.sessions.lock().expect("phone auth lock");
        let entry = guard.get_mut(token)?;
        if entry.expires_at_ms < epoch_ms() {
            guard.remove(token);
            return None;
        }
        entry.verified = true;

        Some(PhoneAuthIdentity {
            phone: entry.phone.clone(),
            label: entry.label.clone(),
            display_name: entry.display_name.clone(),
            session_token: entry.token.clone(),
        })
    }

    fn verified_identity(
        &self,
        token: &str,
        phone: &str,
    ) -> Option<IdentityDescriptor> {
        let guard = self.sessions.lock().expect("phone auth lock");
        let entry = guard.get(token)?;
        if entry.expires_at_ms < epoch_ms() || !entry.verified {
            return None;
        }
        if entry.phone != phone {
            return None;
        }
        Some(IdentityDescriptor {
            phone: entry.phone.clone(),
            label: entry.label.clone(),
            display_name: entry.display_name.clone(),
            presence_state: "online".into(),
        })
    }
}

fn epoch_ms() -> i64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}
