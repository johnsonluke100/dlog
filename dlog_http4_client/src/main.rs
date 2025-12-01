use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{error, info};
use uuid::Uuid;

#[derive(Debug, Serialize)]
struct HandshakeRequest {
    client_id: String,
    capabilities: Vec<String>,
    requested_routes: Vec<String>,
}

#[derive(Debug, Deserialize)]
struct HandshakeResponse {
    session_id: String,
    kernel_version: String,
    motd: String,
    granted_routes: Vec<RouteHint>,
}

#[derive(Debug, Deserialize)]
struct RouteHint {
    omega_path: String,
    target: String,
    confidence: f32,
}

#[derive(Debug, Serialize)]
struct FrameEnvelope {
    session_id: String,
    seq: u64,
    namespace: String,
    kind: FrameKind,
    payload: serde_json::Value,
}

#[derive(Debug, Deserialize)]
struct FrameAck {
    session_id: String,
    seq: u64,
    accepted: bool,
    routed: Vec<RouteHint>,
    notes: Vec<String>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
enum FrameKind {
    TickFrame,
    Query,
    Event,
    MineJob,
    MineResult,
    Dns,
    Audio,
    Game,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_target(false)
        .with_level(true)
        .init();

    let endpoint =
        std::env::var("OMEGA_EDGE").unwrap_or_else(|_| "http://127.0.0.1:8080".to_string());
    let client = Client::builder().timeout(Duration::from_secs(5)).build()?;

    info!("Ω client targeting {}", endpoint);
    let handshake_resp = client
        .post(format!("{endpoint}/omega/handshake"))
        .json(&HandshakeRequest {
            client_id: Uuid::new_v4().to_string(),
            capabilities: vec!["render".into(), "mining".into()],
            requested_routes: vec![";∞;bank;infinity;".into()],
        })
        .send()
        .await?
        .error_for_status()?
        .json::<HandshakeResponse>()
        .await?;

    info!(
        "Handshake ok: {}",
        serde_json::to_string_pretty(&handshake_resp.motd)?
    );

    for seq in 0..3 {
        let frame = FrameEnvelope {
            session_id: handshake_resp.session_id.clone(),
            seq,
            namespace: ";∞;bank;infinity;balances;".into(),
            kind: FrameKind::Query,
            payload: serde_json::json!({
                "kind": "balance_query",
                "label": ";9132077554;comet;"
            }),
        };

        let ack = client
            .post(format!("{endpoint}/omega/frame"))
            .json(&frame)
            .send()
            .await?
            .error_for_status()?
            .json::<FrameAck>()
            .await?;

        info!("Frame {} ack notes: {:?}", seq, ack.notes);
    }

    let status = client
        .get(format!("{endpoint}/omega/status"))
        .send()
        .await?
        .error_for_status()?
        .text()
        .await?;
    info!("Gateway status: {}", status);

    Ok(())
}
