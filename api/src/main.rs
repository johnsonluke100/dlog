// api/src/main.rs
//
// Axum HTTP server that exposes:
// - GET  /health
// - GET  /config
// - GET  /snapshot
// - GET  /balance?phone=&label=
// - POST /transfer              (body: TransferTx JSON)
// - GET  /planets               (list φ-planet specs)
// - GET  /phi_gravity?id=earth  (φ^?-per-tick gravity profile)
// - GET  /omega/master_root     (UniverseSnapshot, 9∞ root style)
// - GET  /omega/label_path?phone=&label= (Ω LabelUniversePath)
//
// Later:
// - add auth integration
// - wire in real persistence and ∞ filesystem folding/unfolding.

use std::net::SocketAddr;
use std::sync::{Arc, Mutex};

use axum::{
    extract::{Query, State},
    routing::{get, post},
    Json, Router,
};
use corelib::{compute_phi_gravity, default_planets, label_universe_path, UniverseState};
use serde::{Deserialize, Serialize};
use spec::{
    Balance, BalanceView, LabelId, LabelUniversePath, NodeConfig, PhiGravityProfile, PlanetSpec,
    TransferTx, UniverseSnapshot,
};

#[derive(Clone)]
struct AppState {
    universe: Arc<Mutex<UniverseState>>,
    config: NodeConfig,
}

#[derive(Debug, Deserialize)]
struct BalanceQuery {
    phone: String,
    label: String,
}

#[derive(Debug, Deserialize)]
struct PlanetQuery {
    id: String,
}

#[derive(Debug, Serialize)]
struct TransferResponse {
    ok: bool,
    error: Option<String>,
    from_balance: Option<Balance>,
    to_balance: Option<Balance>,
}

#[derive(Debug, Serialize)]
struct PhiGravityResponse {
    ok: bool,
    error: Option<String>,
    profile: Option<PhiGravityProfile>,
}

#[tokio::main]
async fn main() {
    let config = load_config();

    println!("api: starting node '{}'", config.node_name);
    println!("api: bind_addr = {}", config.bind_addr);
    if let Some(url) = &config.public_url {
        println!("api: public_url = {}", url);
    }

    // Resolve bind address up front; fall back if parse fails.
    let bind_addr: SocketAddr = config
        .bind_addr
        .parse()
        .unwrap_or_else(|_| "0.0.0.0:8080".parse().unwrap());

    let mut universe = UniverseState::new();
    // Seed a tiny test balance so you can play with transfer immediately.
    let genesis_label = LabelId {
        phone: "TEST".to_string(),
        label: "genesis".to_string(),
    };
    universe.set_balance(
        genesis_label.clone(),
        Balance {
            amount: 1_000_000,
        },
    );
    println!(
        "api: seeded label TEST/genesis with 1_000_000 units for testing transfers."
    );

    let state = AppState {
        universe: Arc::new(Mutex::new(universe)),
        config: config.clone(),
    };

    let app = Router::new()
        .route("/health", get(health))
        .route("/config", get(config_handler))
        .route("/snapshot", get(snapshot))
        .route("/balance", get(balance))
        .route("/transfer", post(transfer))
        .route("/planets", get(planets))
        .route("/phi_gravity", get(phi_gravity))
        .route("/omega/master_root", get(omega_master_root))
        .route("/omega/label_path", get(omega_label_path))
        .with_state(state);

    println!("api: listening on http://{bind_addr}");
    axum::Server::bind(&bind_addr)
        .serve(app.into_make_service())
        .await
        .expect("server failed");
}

fn load_config() -> NodeConfig {
    let path = "dlog.toml";
    match std::fs::read_to_string(path) {
        Ok(contents) => match toml::from_str::<NodeConfig>(&contents) {
            Ok(cfg) => cfg,
            Err(e) => {
                eprintln!("api: failed to parse {}: {e}", path);
                NodeConfig::default()
            }
        },
        Err(_) => {
            eprintln!("api: no {}, using default config", path);
            NodeConfig::default()
        }
    }
}

async fn health() -> &'static str {
    "ok"
}

async fn config_handler(State(state): State<AppState>) -> Json<NodeConfig> {
    Json(state.config.clone())
}

async fn snapshot(State(state): State<AppState>) -> Json<UniverseSnapshot> {
    let mut guard = state.universe.lock().expect("universe lock poisoned");
    let snapshot = guard.fold_snapshot();
    Json(snapshot)
}

async fn balance(
    State(state): State<AppState>,
    Query(q): Query<BalanceQuery>,
) -> Json<BalanceView> {
    let guard = state.universe.lock().expect("universe lock poisoned");
    let label = LabelId {
        phone: q.phone,
        label: q.label,
    };
    let balance = guard.balance_of(&label);
    Json(BalanceView { label, balance })
}

async fn transfer(
    State(state): State<AppState>,
    Json(tx): Json<TransferTx>,
) -> Json<TransferResponse> {
    let mut guard = state.universe.lock().expect("universe lock poisoned");

    let from_before = guard.balance_of(&tx.from);
    let to_before = guard.balance_of(&tx.to);

    let result = guard.apply_transfer(&tx);

    match result {
        Ok(()) => {
            let from_after = guard.balance_of(&tx.from);
            let to_after = guard.balance_of(&tx.to);
            Json(TransferResponse {
                ok: true,
                error: None,
                from_balance: Some(from_after),
                to_balance: Some(to_after),
            })
        }
        Err(e) => Json(TransferResponse {
            ok: false,
            error: Some(e.to_string()),
            from_balance: Some(from_before),
            to_balance: Some(to_before),
        }),
    }
}

async fn planets() -> Json<Vec<PlanetSpec>> {
    let list = default_planets();
    Json(list)
}

async fn phi_gravity(Query(q): Query<PlanetQuery>) -> Json<PhiGravityResponse> {
    let profile = compute_phi_gravity(&q.id);
    match profile {
        Some(p) => Json(PhiGravityResponse {
            ok: true,
            error: None,
            profile: Some(p),
        }),
        None => Json(PhiGravityResponse {
            ok: false,
            error: Some(format!("unknown planet id '{}'", q.id)),
            profile: None,
        }),
    }
}

/// 9∞ master root-style endpoint.
/// For now this just folds a new snapshot (incrementing height) and returns it.
async fn omega_master_root(
    State(state): State<AppState>,
) -> Json<UniverseSnapshot> {
    let mut guard = state.universe.lock().expect("universe lock poisoned");
    let snapshot = guard.fold_snapshot();
    Json(snapshot)
}

/// Ω label universe path endpoint:
/// GET /omega/label_path?phone=&label=
/// → { phone, label, path: ";phone;label;∞;…;hash;" }
async fn omega_label_path(Query(q): Query<BalanceQuery>) -> Json<LabelUniversePath> {
    let view = label_universe_path(&q.phone, &q.label);
    Json(view)
}
