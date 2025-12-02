use axum::{
    extract::State,
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::{
    collections::HashMap,
    net::SocketAddr,
    sync::{Arc, Mutex},
};
use uuid::Uuid;

#[derive(Clone, Debug, Serialize, Deserialize)]
struct PresenceRecord {
    phone: String,
    label: String,
    display_name: String,
    source: PresenceSource,
    session_id: String,
    state: PresenceState,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum PresenceSource {
    Mojang,
    Web,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
enum PresenceState {
    Online,
    Idle,
    Offline,
}

#[derive(Clone, Debug, Deserialize)]
struct MojangPresenceRequest {
    gamer_tag: String,
    mojang_uuid: String,
    phone: String,
    label: String,
    display_name: Option<String>,
}

#[derive(Clone, Debug, Deserialize)]
struct WebPresenceRequest {
    phone: String,
    label: String,
    session_token: String,
    display_name: String,
}

#[derive(Clone, Debug, Deserialize)]
struct HeartbeatRequest {
    session_id: String,
    state: PresenceState,
}

#[derive(Clone, Debug, Serialize)]
struct PresenceResponse {
    status: &'static str,
    record: Option<PresenceRecord>,
}

#[derive(Clone)]
struct AppState {
    records: Arc<Mutex<HashMap<String, PresenceRecord>>>,
}

#[tokio::main]
async fn main() {
    let state = AppState {
        records: Arc::new(Mutex::new(HashMap::new())),
    };

    let app = Router::new()
        .route("/presence/mojang", post(register_mojang))
        .route("/presence/web", post(register_web))
        .route("/presence/heartbeat", post(heartbeat))
        .route("/presence/:phone", get(get_presence))
        .with_state(state);

    let addr: SocketAddr = "0.0.0.0:4000".parse().expect("invalid bind address");
    println!("presence_service listening on http://{addr}");

    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await
        .expect("server error");
}

async fn register_mojang(
    State(state): State<AppState>,
    Json(payload): Json<MojangPresenceRequest>,
) -> StatusCode {
    let mut records = state.records.lock().expect("records mutex poisoned");
    let session_id = Uuid::new_v4().to_string();
    records.insert(
        payload.phone.clone(),
        PresenceRecord {
            phone: payload.phone,
            label: payload.label,
            display_name: payload
                .display_name
                .unwrap_or_else(|| payload.gamer_tag.clone()),
            source: PresenceSource::Mojang,
            session_id,
            state: PresenceState::Online,
        },
    );
    StatusCode::NO_CONTENT
}

async fn register_web(
    State(state): State<AppState>,
    Json(payload): Json<WebPresenceRequest>,
) -> StatusCode {
    let mut records = state.records.lock().expect("records mutex poisoned");
    records.insert(
        payload.phone.clone(),
        PresenceRecord {
            phone: payload.phone,
            label: payload.label,
            display_name: payload.display_name,
            source: PresenceSource::Web,
            session_id: payload.session_token,
            state: PresenceState::Online,
        },
    );
    StatusCode::NO_CONTENT
}

async fn heartbeat(
    State(state): State<AppState>,
    Json(payload): Json<HeartbeatRequest>,
) -> StatusCode {
    let mut records = state.records.lock().expect("records mutex poisoned");
    if let Some(record) = records
        .values_mut()
        .find(|r| r.session_id == payload.session_id)
    {
        record.state = payload.state;
        StatusCode::NO_CONTENT
    } else {
        StatusCode::NOT_FOUND
    }
}

async fn get_presence(
    State(state): State<AppState>,
    axum::extract::Path(phone): axum::extract::Path<String>,
) -> Json<PresenceResponse> {
    let records = state.records.lock().expect("records mutex poisoned");
    let record = records.get(&phone).cloned();
    Json(PresenceResponse {
        status: if record.is_some() { "ok" } else { "not_found" },
        record,
    })
}
