use clap::{Parser, Subcommand};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::info;
use uuid::Uuid;

#[derive(Parser, Debug)]
#[command(
    name = "dlog_http4_client",
    about = "Probe the DLOG HTTP-4 gateway and bank routes",
    disable_help_subcommand = true
)]
struct Args {
    /// Target HTTP-4 endpoint (default: http://127.0.0.1:8080 or $OMEGA_EDGE)
    #[arg(long, env = "OMEGA_EDGE", default_value = "http://127.0.0.1:8080")]
    endpoint: String,

    /// Phone number to authenticate with (default: $DLOG_PHONE or 9132077554)
    #[arg(long, env = "DLOG_PHONE", default_value = "9132077554")]
    phone: String,

    /// Label for the client identity (default: $DLOG_LABEL or comet)
    #[arg(long, env = "DLOG_LABEL", default_value = "comet")]
    label: String,

    /// Display name used during signup (default: $DLOG_DISPLAY or Ω Remote)
    #[arg(long, env = "DLOG_DISPLAY", default_value = "Ω Remote")]
    display_name: String,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Subcommand, Debug, Clone)]
enum Command {
    /// Perform the full login → handshake → bank probe flow
    Probe {
        /// Destination label for the transfer probe
        #[arg(long, default_value = "fun")]
        to_label: String,

        /// Amount (in the smallest unit) to move during the transfer probe
        #[arg(long, default_value_t = 50_000)]
        amount: u64,
    },

    /// Fetch gateway status without performing auth flows
    Status,
}

impl Default for Command {
    fn default() -> Self {
        Command::Probe {
            to_label: "fun".into(),
            amount: 50_000,
        }
    }
}

#[derive(Debug, Serialize)]
struct HandshakeRequest {
    client_id: String,
    capabilities: Vec<String>,
    requested_routes: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    phone: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    session_token: Option<String>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct HandshakeResponse {
    session_id: String,
    kernel_version: String,
    motd: String,
    granted_routes: Vec<RouteHint>,
    identity: Option<IdentityDescriptor>,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct PhoneStartResponse {
    session_token: String,
    expires_in_ms: i64,
    biometric_required: bool,
    instructions: String,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct PhoneConfirmResponse {
    status: String,
    verified: bool,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct RouteHint {
    omega_path: String,
    target: String,
    confidence: f32,
}

#[allow(dead_code)]
#[derive(Debug, Deserialize)]
struct IdentityDescriptor {
    phone: String,
    label: String,
    display_name: String,
    presence_state: String,
}

#[derive(Debug, Serialize)]
struct FrameEnvelope {
    session_id: String,
    seq: u64,
    namespace: String,
    kind: FrameKind,
    payload: serde_json::Value,
}

#[allow(dead_code)]
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

#[derive(Debug)]
struct ClientIdentity {
    phone: String,
    label: String,
    display_name: String,
    session_token: String,
}

#[allow(dead_code)]
#[derive(Debug, Serialize)]
struct WebPresencePayload {
    phone: String,
    label: String,
    session_token: String,
    display_name: String,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_target(false)
        .with_level(true)
        .init();

    let args = Args::parse();
    let endpoint = args.endpoint.clone();
    let client = Client::builder().timeout(Duration::from_secs(5)).build()?;

    match args.command.unwrap_or_default() {
        Command::Probe { to_label, amount } => {
            let client_identity = login_via_phone(
                &client,
                &endpoint,
                &args.phone,
                &args.label,
                &args.display_name,
            )
            .await?;
            info!(
                "Ω client targeting {} as {} ({}) display:{} token:{}",
                endpoint,
                client_identity.phone,
                client_identity.label,
                client_identity.display_name,
                client_identity.session_token
            );

            pull_signup_frames(&client, &endpoint).await?;

            let handshake_resp = handshake(&client, &endpoint, &client_identity).await?;
            if let Some(identity) = &handshake_resp.identity {
                info!(
                    "Handshake acknowledged presence {} [{}]",
                    identity.phone, identity.presence_state
                );
            }
            info!("Handshake motd: {}", handshake_resp.motd);

            balance_probe(
                &client,
                &endpoint,
                &handshake_resp.session_id,
                &omega_label(&client_identity.phone, &client_identity.label),
            )
            .await?;
            transfer_probe(
                &client,
                &endpoint,
                &handshake_resp.session_id,
                &omega_label(&client_identity.phone, &client_identity.label),
                &omega_label(&client_identity.phone, &to_label),
                amount,
            )
            .await?;
            balance_probe(
                &client,
                &endpoint,
                &handshake_resp.session_id,
                &omega_label(&client_identity.phone, &to_label),
            )
            .await?;

            let status = client
                .get(format!("{endpoint}/omega/status"))
                .send()
                .await?
                .error_for_status()?
                .text()
                .await?;
            info!("Gateway status: {}", status);
        }
        Command::Status => {
            let status = client
                .get(format!("{endpoint}/omega/status"))
                .send()
                .await?
                .error_for_status()?
                .text()
                .await?;
            info!("Gateway status: {}", status);
        }
    }

    Ok(())
}

async fn handshake(
    client: &Client,
    endpoint: &str,
    identity: &ClientIdentity,
) -> anyhow::Result<HandshakeResponse> {
    Ok(client
        .post(format!("{endpoint}/omega/handshake"))
        .json(&HandshakeRequest {
            client_id: Uuid::new_v4().to_string(),
            capabilities: vec!["render".into(), "banking".into()],
            requested_routes: vec![";∞;bank;infinity;".into()],
            phone: Some(identity.phone.clone()),
            session_token: Some(identity.session_token.clone()),
        })
        .send()
        .await?
        .error_for_status()?
        .json::<HandshakeResponse>()
        .await?)
}

async fn balance_probe(
    client: &Client,
    endpoint: &str,
    session_id: &str,
    label: &str,
) -> anyhow::Result<()> {
    let frame = FrameEnvelope {
        session_id: session_id.into(),
        seq: rand_seq(),
        namespace: ";∞;bank;infinity;balances;".into(),
        kind: FrameKind::Query,
        payload: serde_json::json!({
            "kind": "balance_query",
            "label": label
        }),
    };
    let ack = send_frame(client, endpoint, frame).await?;
    info!("Balance probe for {label}: {:?}", ack.notes);
    Ok(())
}

async fn transfer_probe(
    client: &Client,
    endpoint: &str,
    session_id: &str,
    from: &str,
    to: &str,
    amount: u64,
) -> anyhow::Result<()> {
    let frame = FrameEnvelope {
        session_id: session_id.into(),
        seq: rand_seq(),
        namespace: ";∞;bank;infinity;transfer;".into(),
        kind: FrameKind::Event,
        payload: serde_json::json!({
            "kind": "transfer",
            "from": from,
            "to": to,
            "amount": amount,
        }),
    };
    let ack = send_frame(client, endpoint, frame).await?;
    info!("Transfer probe {from} → {to}: {:?}", ack.notes);
    Ok(())
}

async fn send_frame(
    client: &Client,
    endpoint: &str,
    frame: FrameEnvelope,
) -> anyhow::Result<FrameAck> {
    Ok(client
        .post(format!("{endpoint}/omega/frame"))
        .json(&frame)
        .send()
        .await?
        .error_for_status()?
        .json::<FrameAck>()
        .await?)
}

fn rand_seq() -> u64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos() as u64
}

async fn start_phone_session(
    client: &Client,
    endpoint: &str,
    phone: &str,
    label: &str,
    display_name: &str,
) -> anyhow::Result<String> {
    let resp = client
        .post(format!("{endpoint}/auth/phone/start"))
        .json(&serde_json::json!({
            "phone": phone,
            "label": label,
            "display_name": display_name,
        }))
        .send()
        .await?
        .error_for_status()?
        .json::<PhoneStartResponse>()
        .await?;

    Ok(resp.session_token)
}

async fn confirm_phone_session(
    client: &Client,
    endpoint: &str,
    session_token: &str,
) -> anyhow::Result<()> {
    let biometric_signature =
        std::env::var("DLOG_BIOMETRIC").unwrap_or_else(|_| "biometric-ok".into());

    let resp = client
        .post(format!("{endpoint}/auth/phone/confirm"))
        .json(&serde_json::json!({
            "session_token": session_token,
            "biometric_signature": biometric_signature,
        }))
        .send()
        .await?
        .error_for_status()?
        .json::<PhoneConfirmResponse>()
        .await?;

    if resp.verified {
        Ok(())
    } else {
        Err(anyhow::anyhow!("biometric confirmation failed"))
    }
}

async fn login_via_phone(
    client: &Client,
    endpoint: &str,
    phone: &str,
    label: &str,
    display_name: &str,
) -> anyhow::Result<ClientIdentity> {
    let session_token = start_phone_session(client, endpoint, phone, label, display_name).await?;
    confirm_phone_session(client, endpoint, &session_token).await?;

    Ok(ClientIdentity {
        phone: phone.to_string(),
        label: label.to_string(),
        display_name: display_name.to_string(),
        session_token,
    })
}

fn omega_label(phone: &str, label: &str) -> String {
    format!(";{phone};{label};")
}

async fn pull_signup_frames(client: &Client, endpoint: &str) -> anyhow::Result<()> {
    const LOOPS: usize = 4;
    let mut cursor: usize = 0;

    for _ in 0..LOOPS {
        let url = format!("{endpoint}/signup/frame?cursor={cursor}");
        let resp = client.get(url).send().await?.error_for_status()?;
        let next_cursor = resp
            .headers()
            .get("x-next-cursor")
            .and_then(|value| value.to_str().ok())
            .and_then(|s| s.parse::<usize>().ok())
            .unwrap_or(cursor.wrapping_add(1));

        let frame = resp.text().await?;
        if !frame.trim().is_empty() {
            info!("[signup] {}", frame.trim());
        }

        cursor = next_cursor;
    }

    Ok(())
}
