#!/usr/bin/env bash
#
# refold.command — Ω-Physics launcher for DLOG / dlog.gold
#
# Golden bricks:
#   - ping      → show environment + config
#   - beat      → write stack/sky/dashboard + apply kube manifests
#   - flames    → write Ω flame control (8888 Hz default)
#   - deploy    → build + deploy Cloud Run dlog-gold-app
#   - domains   → status | map   (Cloud Run domain-mappings + DNS dig)
#   - rails     → sample anycast IPs into 8 Ω-bands
#   - shields   → once | watch   (Cloud Armor + backend-service attach)
#   - flow      → ping → beat → flames → deploy → domains → rails
#
# Usage examples:
#   ~/Desktop/refold.command ping
#   ~/Desktop/refold.command beat
#   ~/Desktop/refold.command flames           # default 8888 Hz
#   ~/Desktop/refold.command flames hz 7777
#   ~/Desktop/refold.command deploy
#   ~/Desktop/refold.command domains status
#   ~/Desktop/refold.command domains map
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields once
#   BACKEND_SERVICE="dlog-gold-backend" ~/Desktop/refold.command shields watch
#   ~/Desktop/refold.command flow
#

set -euo pipefail

# ────────────────────────────────────────────────────────────────────────────────
# Core golden constants
# ────────────────────────────────────────────────────────────────────────────────

DLOG_ROOT="${DLOG_ROOT:-"$HOME/Desktop/dlog"}"
OMEGA_ROOT="${OMEGA_ROOT:-"$DLOG_ROOT"}"
STACK_ROOT="${STACK_ROOT:-"$DLOG_ROOT/stack"}"
KUBE_ROOT="${KUBE_ROOT:-"$DLOG_ROOT/kube"}"
UNIVERSE_NS="${UNIVERSE_NS:-dlog-universe}"
OMEGA_INF_ROOT="${OMEGA_INF_ROOT:-"$DLOG_ROOT/∞"}"

PROJECT_ID="${PROJECT_ID:-dlog-gold}"
RUN_REGION="${RUN_REGION:-us-central1}"
RUN_PLATFORM="${RUN_PLATFORM:-managed}"
CLOUD_RUN_SERVICE="${CLOUD_RUN_SERVICE:-dlog-gold-app}"

# Domains in the Ω-triangle
DOMAINS=( "dlog.gold" "goldengold.gold" "nedlog.gold" )

# Cloud Armor policy
ARMOR_POLICY="${ARMOR_POLICY:-dlog-gold-armor}"

# Default Ω-flames
DEFAULT_FLAME_HZ="${DEFAULT_FLAME_HZ:-8888}"
DEFAULT_FLAME_HEIGHT="${DEFAULT_FLAME_HEIGHT:-7}"
DEFAULT_FLAME_FRICTION="${DEFAULT_FLAME_FRICTION:-leidenfrost}"

# Rails / bands
RAIL_BANDS=8

# ────────────────────────────────────────────────────────────────────────────────
# Helpers
# ────────────────────────────────────────────────────────────────────────────────

ts() {
  date '+%Y-%m-%d %H:%M:%S'
}

log() {
  printf '[%s] %s\n' "$(ts)" "$*" >&2
}

soft_warn() {
  printf '[%s] [warn] %s\n' "$(ts)" "$*" >&2
}

ensure_dirs() {
  mkdir -p "$STACK_ROOT" \
           "$DLOG_ROOT/dashboard" \
           "$DLOG_ROOT/sky" \
           "$DLOG_ROOT/flames" \
           "$DLOG_ROOT/∞"
}

# Run a command but never kill the whole script if it fails
try_run() {
  # usage: try_run <label> <cmd...>
  local label="$1"; shift
  if ! "$@" >/tmp/refold-"$label".out 2>/tmp/refold-"$label".err; then
    soft_warn "$label command failed (rc=$?)"
    soft_warn "$label stderr: $(sed -e 's/$/\\n/' </tmp/refold-"$label".err | tr -d '\n')"
    return 1
  fi
}

# ────────────────────────────────────────────────────────────────────────────────
# ping
# ────────────────────────────────────────────────────────────────────────────────

cmd_ping() {
  cat <<EOF
Desktop:          $HOME/Desktop
DLOG_ROOT:        $DLOG_ROOT
OMEGA_ROOT:       $OMEGA_ROOT
STACK_ROOT:       $STACK_ROOT
UNIVERSE_NS:      $UNIVERSE_NS
KUBE_MANIFEST:    $KUBE_ROOT
Ω-INF-ROOT:       $OMEGA_INF_ROOT
PROJECT_ID:       $PROJECT_ID
RUN_REGION:       $RUN_REGION
RUN_PLATFORM:     $RUN_PLATFORM
CLOUD_RUN_SERVICE:$CLOUD_RUN_SERVICE
BACKEND_SERVICE:  ${BACKEND_SERVICE:-<unset>}
EOF
}

# ────────────────────────────────────────────────────────────────────────────────
# beat — stack snapshot + dashboard + sky + kube manifests
# ────────────────────────────────────────────────────────────────────────────────

cmd_beat() {
  ensure_dirs
  local epoch
  epoch="$(date +%s)"

  # Stack snapshot
  local stack_file="$STACK_ROOT/stack;universe"
  log "[beat] wrote stack snapshot → $stack_file"
  {
    printf ';stack;epoch;%s;ok;\n' "$epoch"
    printf ';phone;label;epoch;epoch8;tag;status;\n'
  } >"$stack_file"

  # 9∞ master root
  local nine_root="$OMEGA_INF_ROOT/9∞.txt"
  log "[beat] wrote 9∞ master root → $nine_root"
  {
    printf ';9∞;epoch;%s;root;ok;\n' "$epoch"
    printf ';cpu=heart;gpu=brain;omega=%s;four;flames;rise;\n' "$DEFAULT_FLAME_HZ"
  } >"$nine_root"

  # Dashboard snapshot
  local dash_file="$DLOG_ROOT/dashboard/dashboard;status"
  log "[beat] wrote Ω-dashboard snapshot → $dash_file"
  {
    printf ';dashboard;epoch;%s;project;%s;region;%s;service;%s;\n' \
      "$epoch" "$PROJECT_ID" "$RUN_REGION" "$CLOUD_RUN_SERVICE"
  } >"$dash_file"

  # Sky manifest + timeline
  local sky_manifest="$DLOG_ROOT/sky/sky;manifest"
  local sky_timeline="$DLOG_ROOT/sky/sky;timeline"
  log "[beat] wrote Ω-sky manifest & timeline → $DLOG_ROOT/sky"
  {
    printf ';sky;epoch;%s;omegaHz;%s;bands;%d;\n' \
      "$epoch" "$DEFAULT_FLAME_HZ" "$RAIL_BANDS"
  } >"$sky_manifest"
  {
    printf '%s;sky;tick;beat;\n' "$epoch"
  } >>"$sky_timeline"

  # Apply kube manifests (non-fatal if cluster is away)
  if [ -d "$KUBE_ROOT/universe" ]; then
    log "[beat] applying universe manifests → $KUBE_ROOT/universe (namespace $UNIVERSE_NS)"
    try_run kube-apply kubectl apply -n "$UNIVERSE_NS" -f "$KUBE_ROOT/universe" || true
  else
    soft_warn "[beat] kube universe directory missing at $KUBE_ROOT/universe (ok for now)"
  fi

  log "[beat] complete (stack + dashboard + 9∞)."
}

# ────────────────────────────────────────────────────────────────────────────────
# flames — write Ω flame control
# ────────────────────────────────────────────────────────────────────────────────

cmd_flames() {
  ensure_dirs

  local hz="$DEFAULT_FLAME_HZ"
  if [ "${1-}" = "hz" ] && [ -n "${2-}" ]; then
    hz="$2"
  fi

  local file="$DLOG_ROOT/flames/flames;control"
  echo "[refold] wrote flames control → $file"
  {
    printf 'hz=%s\n' "$hz"
    printf 'height=%s\n' "$DEFAULT_FLAME_HEIGHT"
    printf 'friction=%s\n' "$DEFAULT_FLAME_FRICTION"
    printf 'mode=4_vertical\n'
  } >"$file"

  echo "Flames control: hz=$hz height=$DEFAULT_FLAME_HEIGHT friction=$DEFAULT_FLAME_FRICTION"
  echo "(refold.command itself does not start audio — your Ω-engine must read $file)"
}

# ────────────────────────────────────────────────────────────────────────────────
# deploy — Cloud Run container build + deploy
# ────────────────────────────────────────────────────────────────────────────────

cmd_deploy() {
  ensure_dirs
  echo "=== 🚀 refold.command deploy (Cloud Run) ==="
  echo "[deploy] project:  $PROJECT_ID"
  echo "[deploy] region:   $RUN_REGION"
  echo "[deploy] service:  $CLOUD_RUN_SERVICE"
  echo "[deploy] root:     $DLOG_ROOT"

  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  log "[deploy] building container (Dockerfile) + deploying to Cloud Run…"
  gcloud run deploy "$CLOUD_RUN_SERVICE" \
    --source "$DLOG_ROOT" \
    --platform="$RUN_PLATFORM" \
    --region="$RUN_REGION" \
    --allow-unauthenticated

  echo "[deploy] ✅ Cloud Run deploy complete."
  echo "[deploy] tip: $HOME/Desktop/refold.command domains status"
}

# ────────────────────────────────────────────────────────────────────────────────
# domains status / map
# ────────────────────────────────────────────────────────────────────────────────

domains_status_one() {
  local domain="$1"

  echo
  echo "── $domain ─────────────────────────────"

  # DNS A / AAAA
  echo "[dns] A:"
  if ! dig +short "$domain" A | sed '/^$/d'; then
    soft_warn "[dns] dig A failed for $domain"
  fi

  echo
  echo "[dns] AAAA:"
  if ! dig +short "$domain" AAAA | sed '/^$/d'; then
    soft_warn "[dns] dig AAAA failed for $domain"
  fi
  echo

  # Domain-mapping
  echo "[run] domain-mapping conditions:"
  if out="$(gcloud beta run domain-mappings describe --domain "$domain" 2>&1)"; then
    # Compact view of Ready / CertificateProvisioned if present
    local ready cert
    ready="$(printf '%s\n' "$out" | awk '/type: Ready/{getline; gsub(/'\''/,""); print $2}' || true)"
    cert="$(printf '%s\n' "$out" | awk '/type: CertificateProvisioned/{getline; gsub(/'\''/,""); print $2}' || true)"

    if [ -n "$ready" ] || [ -n "$cert" ]; then
      printf '  Ready = %s\n' "${ready:-<none>}"
      printf '  CertificateProvisioned = %s\n' "${cert:-<none>}"
    else
      printf '%s\n' "$out"
    fi
  else
    echo "  (no domain-mapping found for $domain in $RUN_REGION)"
    echo "  error: $out"
  fi
}

cmd_domains_status() {
  echo "=== 🌐 DLOG DOMAINS – status (DNS + certs) ==="
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  local d
  for d in "${DOMAINS[@]}"; do
    domains_status_one "$d"
  done
}

cmd_domains_map_one() {
  local domain="$1"
  echo
  echo "── $domain ─────────────────────────────"

  if out="$(gcloud beta run domain-mappings describe --domain "$domain" 2>&1)"; then
    echo "[refold] domain-mapping already exists for $domain"
    return 0
  fi

  echo "[refold] creating domain-mapping for $domain → service $CLOUD_RUN_SERVICE…"
  # This may fail if the domain is not verified; handle softly.
  if out2="$(gcloud beta run domain-mappings create \
      --service "$CLOUD_RUN_SERVICE" \
      --domain "$domain" 2>&1)"; then
    printf '%s\n' "$out2"
  else
    echo "[refold] ⚠️ could not create domain-mapping for $domain"
    echo "        - this usually means the domain is not yet verified for project $PROJECT_ID"
    echo "        - or another project has already claimed it"
    echo "  gcloud says:"
    printf '    %s\n' "$out2"
  fi
}

cmd_domains_map() {
  echo "=== 🌐 refold.command domains map ==="
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set run/platform "$RUN_PLATFORM" >/dev/null
  gcloud config set run/region "$RUN_REGION" >/dev/null

  local d
  for d in "${DOMAINS[@]}"; do
    cmd_domains_map_one "$d"
  done
}

# ────────────────────────────────────────────────────────────────────────────────
# rails — sample IPs into Ω-bands
# ────────────────────────────────────────────────────────────────────────────────

cmd_rails() {
  ensure_dirs
  local epoch
  epoch="$(date +%s)"

  echo "=== 🌀 refold.command rails (Ω IP bands) ==="

  # Gather all IPv4 / v6 currently visible for the Ω domains
  local d
  local -a v4_list=()
  local -a v6_list=()

  for d in "${DOMAINS[@]}"; do
    while read -r ip; do
      [ -n "$ip" ] && v4_list+=("$ip")
    done < <(dig +short "$d" A 2>/dev/null || true)

    while read -r ip; do
      [ -n "$ip" ] && v6_list+=("$ip")
    done < <(dig +short "$d" AAAA 2>/dev/null || true)
  done

  local total="${#v4_list[@]}"
  local bands="$RAIL_BANDS"

  printf '[rails] epoch=%s railHz=%s bands=%d\n' "$epoch" "$DEFAULT_FLAME_HZ" "$bands"

  local i band_ip
  for ((i=0; i<bands; i++)); do
    if (( total > 0 )); then
      band_ip="${v4_list[$(( i % total ))]}"
    else
      band_ip="<none>"
    fi
    printf '[rails] band%02d → %s\n' "$i" "$band_ip"
  done

  local rails_file="$STACK_ROOT/rails;omega"
  {
    printf '%s;railHz;%s;bands;%d;v4_total;%d;\n' \
      "$epoch" "$DEFAULT_FLAME_HZ" "$bands" "$total"
  } >>"$rails_file"

  printf '[rails] appended snapshot → %s\n' "$rails_file"
}

# ────────────────────────────────────────────────────────────────────────────────
# shields — Cloud Armor + backend attach
# ────────────────────────────────────────────────────────────────────────────────

ensure_armor_policy() {
  gcloud config set core/project "$PROJECT_ID" >/dev/null
  gcloud config set compute/region "$RUN_REGION" >/dev/null

  echo "[armor] ensuring security policy $ARMOR_POLICY exists…"
  if ! gcloud compute security-policies describe "$ARMOR_POLICY" >/dev/null 2>&1; then
    gcloud compute security-policies create "$ARMOR_POLICY" \
      --description="DLOG GOLD Ω-shield baseline"
  fi

  echo "[armor] ensuring soft allow-all rule 1000 exists…"
  if ! gcloud compute security-policies rules describe 1000 \
        --security-policy "$ARMOR_POLICY" >/dev/null 2>&1; then
    gcloud compute security-policies rules create 1000 \
      --security-policy "$ARMOR_POLICY" \
      --action=allow \
      --description="soft allow-all baseline (tighten later)" \
      --expression="true"
  else
    gcloud compute security-policies rules update 1000 \
      --security-policy "$ARMOR_POLICY" \
      --action=allow \
      --description="soft allow-all baseline (tighten later)" \
      --expression="true"
  fi
}

attach_armor_to_backend() {
  local backend="${BACKEND_SERVICE:-}"
  if [ -z "$backend" ]; then
    soft_warn "[armor] BACKEND_SERVICE not set; skipping backend attach (ok until LB exists)"
    return 0
  fi

  if ! gcloud compute backend-services describe "$backend" --global >/dev/null 2>&1; then
    soft_warn "[armor] backend-service $backend not found yet (ok, create LB later)"
    return 0
  fi

  echo "[armor] attaching policy $ARMOR_POLICY to backend-service $backend…"
  gcloud compute backend-services update "$backend" \
    --security-policy "$ARMOR_POLICY" \
    --global
}

cmd_shields_once() {
  echo "=== 🛡️ refold.command shields once ==="
  ensure_armor_policy
  attach_armor_to_backend
}

cmd_shields_watch() {
  echo "=== 🛡️ refold.command shields watch (8s resets) ==="
  echo "project:   $PROJECT_ID"
  echo "region:    $RUN_REGION"
  echo "service:   $CLOUD_RUN_SERVICE"
  echo "backend:   ${BACKEND_SERVICE:-<unset>}"
  echo "policy:    $ARMOR_POLICY"
  echo
  echo "Every 8 seconds:"
  echo "  - Re-assert Cloud Armor policy + rule 1000"
  echo "  - Try to attach policy to BACKEND_SERVICE (if it exists)"
  echo "  - Refresh Ω-rails from current anycast IPs"
  echo "  - Print a compact dlog.gold domain/cert snapshot"
  echo
  echo "Ctrl+C any time. The Ω-shields keep humming at $DEFAULT_FLAME_HZ Hz."
  echo

  while true; do
    echo "[$(ts)] [shields] --- heartbeat ---"
    ensure_armor_policy
    attach_armor_to_backend

    # Tiny rail + dlog.gold status preview
    cmd_rails
    echo
    domains_status_one "dlog.gold"
    echo
    sleep 8
  done
}

# ────────────────────────────────────────────────────────────────────────────────
# flow — one-button streaming pipeline
# ────────────────────────────────────────────────────────────────────────────────

cmd_flow() {
  echo "=== 🌊 refold.command flow (ping → beat → flames → deploy → domains → rails) ==="
  cmd_ping
  echo
  cmd_beat
  echo
  cmd_flames
  echo
  cmd_deploy
  echo
  cmd_domains_status
  echo
  cmd_rails
  echo
  echo "[flow] done. You can now run, if desired:"
  echo "  export BACKEND_SERVICE=\"dlog-gold-backend\"  # once LB backend exists"
  echo "  $HOME/Desktop/refold.command shields watch"
}

# ────────────────────────────────────────────────────────────────────────────────
# main dispatch
# ────────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: refold.command <subcommand> [args...]

Subcommands:
  ping                       Show Ω-environment
  beat                       Stack + dashboard + sky + kube
  flames [hz <value>]        Write Ω flame control (default $DEFAULT_FLAME_HZ Hz)
  deploy                     Build + deploy Cloud Run service
  domains status             Show DNS + Cloud Run domain-mapping for Ω domains
  domains map                Ensure domain-mappings exist (where verified)
  rails                      Sample IPs into 8 Ω-bands and log to stack
  shields once               One-time Cloud Armor + backend attach
  shields watch              Continuous Ω-shield heartbeat (8s)
  flow                       ping → beat → flames → deploy → domains → rails

Environment:
  PROJECT_ID          (default: $PROJECT_ID)
  RUN_REGION          (default: $RUN_REGION)
  RUN_PLATFORM        (default: $RUN_PLATFORM)
  CLOUD_RUN_SERVICE   (default: $CLOUD_RUN_SERVICE)
  BACKEND_SERVICE     (backend-service name for HTTPS LB, optional)
  ARMOR_POLICY        (default: $ARMOR_POLICY)
EOF
}

# === Ω-BANK (SHA-512 || BLAKE3 "sha-1024" wallet stack) =====================

omega_bank_root() {
  # default to your DLOG root
  if [ -n "${DLOG_ROOT:-}" ]; then
    printf '%s\n' "$DLOG_ROOT/omega_bank"
  else
    printf '%s\n' "$HOME/Desktop/dlog/omega_bank"
  fi
}

omega_bank_init() {
  local ROOT="${DLOG_ROOT:-$HOME/Desktop/dlog}"
  local CRATE_DIR
  CRATE_DIR="$(omega_bank_root)"

  echo "=== 🏦 Ω-BANK INIT ==="
  echo "[bank] ROOT:      $ROOT"
  echo "[bank] CRATE_DIR: $CRATE_DIR"

  mkdir -p "$ROOT"

  if [ ! -d "$CRATE_DIR" ]; then
    echo "[bank] creating omega_bank crate (standalone, not in workspace)…"
    ( cd "$ROOT" && cargo new omega_bank --bin >/dev/null 2>&1 )
  else
    echo "[bank] omega_bank crate already exists, refreshing sources…"
  fi

  # Minimal Cargo.toml – SHA-512 + BLAKE3 + hex
  cat > "$CRATE_DIR/Cargo.toml" << 'EOF'
[package]
name = "omega_bank"
version = "0.1.0"
edition = "2021"

[dependencies]
sha2 = "0.10"
blake3 = "1"
hex = "0.4"
EOF

  # Main Rust file: SHA-512 || BLAKE3 "ΩHASH1024" + 3 × 256 wallet IDs
  cat > "$CRATE_DIR/src/main.rs" << 'EOF'
use sha2::{Sha512, Digest};
use std::env;

/// 1024-bit hash: SHA-512(m) || BLAKE3-512(m)
fn omega_hash1024(input: &[u8]) -> [u8; 128] {
    // SHA-512 half
    let mut sha = Sha512::new();
    sha.update(input);
    let sha_out = sha.finalize(); // 64 bytes

    // BLAKE3-512 half (XOF mode)
    let mut blake_out = [0u8; 64];
    blake3::Hasher::new()
        .update(input)
        .finalize_xof()
        .fill(&mut blake_out);

    // Concatenate
    let mut out = [0u8; 128];
    out[0..64].copy_from_slice(&sha_out);
    out[64..128].copy_from_slice(&blake_out);
    out
}

/// Very simple KDF for now:
///   root_key = SHA-512("ΩBANK" || passphrase)[0..32]
/// For real money, upgrade this to Argon2id.
fn derive_root_key(passphrase: &str) -> [u8; 32] {
    let mut sha = Sha512::new();
    sha.update(b"\xEEOmegaBankRoot");
    sha.update(passphrase.as_bytes());
    let out = sha.finalize();
    let mut root = [0u8; 32];
    root.copy_from_slice(&out[0..32]);
    root
}

fn derive_asset_master(root_key: &[u8; 32], asset_code: u8) -> ([u8; 32], [u8; 32]) {
    // asset_tag = "ΩASSET" || asset_code
    let mut tag = Vec::new();
    tag.extend_from_slice(b"\xEEOmegaAsset");
    tag.push(asset_code);

    // seed = SHA-512(root_key || tag)
    let mut sha = Sha512::new();
    sha.update(root_key);
    sha.update(&tag);
    let seed = sha.finalize(); // 64 bytes

    // 1024-bit expansion
    let hash1024 = omega_hash1024(&seed);

    let mut priv_master = [0u8; 32];
    let mut id_master   = [0u8; 32];

    priv_master.copy_from_slice(&hash1024[0..32]);
    id_master.copy_from_slice(&hash1024[32..64]);

    (priv_master, id_master)
}

/// Derive a single wallet (public ID only) for a given asset + index
fn derive_wallet_id(
    asset_priv_master: &[u8; 32],
    asset_code: u8,
    index: u32,
) -> [u8; 32] {
    let mut path_tag = Vec::new();
    path_tag.extend_from_slice(b"\xEEWalletPath");
    path_tag.push(asset_code);
    path_tag.extend_from_slice(&index.to_be_bytes());

    // child_seed = SHA-512(asset_priv_master || path_tag)
    let mut sha = Sha512::new();
    sha.update(asset_priv_master);
    sha.update(&path_tag);
    let child_seed = sha.finalize();

    // child_hash = ΩHASH1024(child_seed)
    let child_hash = omega_hash1024(&child_seed);

    // child_id = bytes 32..64 (no private scalar output here)
    let mut id = [0u8; 32];
    id.copy_from_slice(&child_hash[32..64]);
    id
}

fn hex32(b: &[u8; 32]) -> String {
    hex::encode(b)
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() <= 1 {
        eprintln!("Usage: omega-bank plan");
        eprintln!("  env OMEGA_BANK_PASSPHRASE must be set.");
        std::process::exit(1);
    }

    let cmd = &args[1];

    let pass = match env::var("OMEGA_BANK_PASSPHRASE") {
        Ok(v) => v,
        Err(_) => {
            eprintln!("OMEGA_BANK_PASSPHRASE not set.");
            std::process::exit(1);
        }
    };

    let root_key = derive_root_key(&pass);

    // Asset codes: 1 = XAUT, 2 = BTC, 3 = DOGE
    let assets = [
        (1u8, "XAUT"),
        (2u8, "BTC"),
        (3u8, "DOGE"),
    ];

    match cmd.as_str() {
        "plan" => {
            println!("=== 🏦 Ω-BANK PLAN (view-only IDs) ===");
            println!("(derived from OMEGA_BANK_PASSPHRASE via SHA-512 || BLAKE3)");
            println!();

            for (code, name) in &assets {
                let (priv_master, id_master) = derive_asset_master(&root_key, *code);
                println!("--- ASSET {name} (code={code}) ---");
                println!("master_id   = {}", hex32(&id_master));
                println!("(master_priv hidden; NEVER printed)");
                println!();

                for i in 0u32..256 {
                    let id = derive_wallet_id(&priv_master, *code, i);
                    println!("{name} idx={:03} id={}", i, hex32(&id));
                }

                println!();
            }
        }
        other => {
            eprintln!("Unknown command: {other}");
            eprintln!("Usage: omega-bank plan");
            std::process::exit(1);
        }
    }
}
EOF

  echo "[bank] omega_bank sources written."
  echo "[bank] building release binary…"
  ( cd "$CRATE_DIR" && cargo build --release ) || {
    echo "[bank] ❌ build failed"; return 1;
  }
  echo "[bank] ✅ omega_bank ready."
}

omega_bank_plan() {
  local CRATE_DIR
  CRATE_DIR="$(omega_bank_root)"

  if [ ! -x "$CRATE_DIR/target/release/omega_bank" ]; then
    echo "[bank] omega_bank binary missing, running init…"
    omega_bank_init || return 1
  fi

  if [ -z "${OMEGA_BANK_PASSPHRASE:-}" ]; then
    echo "[bank] ❌ OMEGA_BANK_PASSPHRASE is not set."
    echo "[bank]    export OMEGA_BANK_PASSPHRASE='your-strong-passphrase'"
    return 1
  fi

  echo "=== 🏦 Ω-BANK PLAN via omega_bank (SHA-512 || BLAKE3) ==="
  ( cd "$CRATE_DIR" && OMEGA_BANK_PASSPHRASE="$OMEGA_BANK_PASSPHRASE" ./target/release/omega_bank plan )
}

cmd_bank() {
  local sub="${1:-help}"
  shift || true
  case "$sub" in
    init)
      omega_bank_init "$@"
      ;;
    plan)
      omega_bank_plan "$@"
      ;;
    *)
      cat << 'EOF'
Usage: refold.command bank <subcommand>

  bank init   - create/update ω-bank Rust crate (SHA-512 || BLAKE3)
  bank plan   - print XAUT/BTC/DOGE × 256 wallet IDs (no priv keys)

Examples:

  export OMEGA_BANK_PASSPHRASE='use-a-strong-secret'
  ~/Desktop/refold.command bank init
  ~/Desktop/refold.command bank plan
EOF
      ;;
  esac
}
# === end Ω-BANK section ======================================================



main() {
  local cmd="${1-}"
  shift || true

  case "$cmd" in
    ping)          cmd_ping "$@" ;;
    beat)          cmd_beat "$@" ;;
    flames)        cmd_flames "$@" ;;
    deploy)        cmd_deploy "$@" ;;
    domains)
      local sub="${1-}"; shift || true
      case "$sub" in
        status) cmd_domains_status ;;
        map)    cmd_domains_map ;;
        *)      usage; exit 1 ;;
      esac
      ;;
    rails)         cmd_rails "$@" ;;
    shields)
      local sub="${1-}"; shift || true
      case "$sub" in
        once)  cmd_shields_once ;;
        watch) cmd_shields_watch ;;
        *)     usage; exit 1 ;;
      esac
      ;;
    flow)          cmd_flow "$@" ;;
    ""|help|-h|--help) usage ;;
    *)             usage; exit 1 ;;
    bank)    cmd_bank "$@" ;;

  esac
}

main "$@"
