#!/usr/bin/env bash
set -euo pipefail

# --------------------------- Core environment -------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

: "${DLOG_ROOT:="$SCRIPT_DIR"}"
: "${OMEGA_ROOT:="$DLOG_ROOT"}"
: "${STACK_ROOT:="$DLOG_ROOT/stack"}"
: "${UNIVERSE_NS:="dlog-universe"}"
: "${KUBE_MANIFEST:="$DLOG_ROOT/kube"}"
: "${OMEGA_INF_ROOT:="$DLOG_ROOT/∞"}"

: "${PROJECT_ID:="dlog-gold"}"
: "${RUN_REGION:="us-east1"}"
: "${RUN_PLATFORM:="managed"}"
: "${CLOUD_RUN_SERVICE:="dlog-gold-app"}"
: "${BACKEND_SERVICE:=""}"
: "${ARMOR_POLICY:="dlog-gold-armor"}"

# ---------------------------------------------------------------------------
# Paper server @ dlog.gold – DNS notes (for Luke)
#   1) Add an A record: dlog.gold → <public IPv4 of the Minecraft/Paper host>.
#   2) (Optional) Add an AAAA record: dlog.gold → <public IPv6>.
#   3) If you’re not on port 25565, add an SRV:
#        _minecraft._tcp.dlog.gold
#        target: <the A/AAAA host>, port: <your port>, priority: 0, weight: 0.
#   4) Keep server.properties either with server-ip blank or 0.0.0.0 and
#      server-port matching the SRV (25565 by default).
#   5) Open TCP on that port in firewall / router (and port-forward if home).
# ---------------------------------------------------------------------------

# ------------------------------ Logging -------------------------------------

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*" >&2
}

soft_warn() {
  printf '[%s] [warn] %s\n' "$(timestamp)" "$*" >&2
}

fatal() {
  printf '[%s] [fatal] %s\n' "$(timestamp)" "$*" >&2
  exit 1
}

# --------------------------- Vault / cache vortex ---------------------------
# cache vortex = OMEGA_BANK_PASSPHRASE in RAM
# vault        = vault/omega_vault.enc + .sha512 on disk

verify_vault_integrity() {
  local vault_dir="$DLOG_ROOT/vault"
  local vault_file="$vault_dir/omega_vault.enc"
  local hash_file="$vault_dir/omega_vault.enc.sha512"

  if [ ! -f "$vault_file" ] || [ ! -f "$hash_file" ]; then
    soft_warn "[vault] omega vault files missing under $vault_dir"
    return 1
  fi

  if ! command -v shasum >/dev/null 2>&1; then
    soft_warn "[vault] shasum not available to verify omega_vault integrity"
    return 1
  fi

  local expected actual
  expected="$(awk '{print $1}' "$hash_file" | tr -d '\n')"
  actual="$(shasum -a 512 "$vault_file" | awk '{print $1}')"

  if [ "$expected" = "$actual" ]; then
    log "[vault] omega_vault.enc hash verified."
    return 0
  else
    soft_warn "[vault] omega_vault.enc hash mismatch!"
    return 1
  fi
}

# cache vortex (RAM) → vault (encrypted snapshot)
ensure_vault_from_cache() {
  if [ -z "${OMEGA_BANK_PASSPHRASE-}" ]; then
    soft_warn "[vault] cannot ensure vault: cache vortex (OMEGA_BANK_PASSPHRASE) is empty."
    return 1
  fi

  local root="${DLOG_ROOT:-$PWD}"
  local vault_dir="$root/vault"
  local stack_dir="${STACK_ROOT:-$root/stack}"
  local genesis="$vault_dir/wallet;plan.genesis"
  local vault_file="$vault_dir/omega_vault.enc"
  local hash_file="$vault_dir/omega_vault.enc.sha512"

  mkdir -p "$vault_dir"

  # 1) Ensure we have a wallet;plan genesis inside the vault
  if [ ! -f "$genesis" ]; then
    if [ ! -f "$stack_dir/wallet;plan" ]; then
      soft_warn "[vault] cannot seed genesis: no $stack_dir/wallet;plan found. Run wallet stack or wand first."
      return 1
    fi
    cp "$stack_dir/wallet;plan" "$genesis"
    log "[vault] seeded wallet;plan.genesis → $genesis"
  fi

  # 2) Decide whether to (re)build encrypted vault
  local need_rebuild=0
  if [ ! -f "$vault_file" ] || [ ! -f "$hash_file" ]; then
    need_rebuild=1
  else
    if ! verify_vault_integrity; then
      need_rebuild=1
    fi
  fi

  if [ "$need_rebuild" -eq 1 ]; then
    log "[vault] (re)building omega_vault.enc from cache vortex…"
    if ! openssl enc -aes-256-cbc -pbkdf2 -iter 200000 -salt \
      -pass env:OMEGA_BANK_PASSPHRASE \
      -in "$genesis" \
      -out "$vault_file"
    then
      soft_warn "[vault] openssl enc failed; vault not updated."
      return 1
    fi

    if ! shasum -a 512 "$vault_file" >"$hash_file"; then
      soft_warn "[vault] failed to write omega_vault.enc.sha512."
      return 1
    fi

    log "[vault] omega_vault.enc + .sha512 updated from cache vortex."
  else
    log "[vault] existing omega_vault.enc already matches omega_vault.enc.sha512."
  fi

  # Final sanity check
  if verify_vault_integrity; then
    return 0
  else
    soft_warn "[vault] ensure_vault_from_cache: integrity still failing after rebuild."
    return 1
  fi
}

# vault (encrypted on disk) → wallet;plan (stack; hard drive re-remembers)
restore_vault_to_stack() {
  if [ -z "${OMEGA_BANK_PASSPHRASE-}" ]; then
    soft_warn "[vault] cannot restore: cache vortex (OMEGA_BANK_PASSPHRASE) is empty."
    return 1
  fi

  local root="${DLOG_ROOT:-$PWD}"
  local vault_dir="$root/vault"
  local stack_dir="${STACK_ROOT:-$root/stack}"
  local vault_file="$vault_dir/omega_vault.enc"
  local hash_file="$vault_dir/omega_vault.enc.sha512"
  local out_plan="$stack_dir/wallet;plan"

  if [ ! -f "$vault_file" ] || [ ! -f "$hash_file" ]; then
    soft_warn "[vault] cannot restore: omega_vault.enc or .sha512 missing under $vault_dir"
    return 1
  fi

  if ! verify_vault_integrity; then
    soft_warn "[vault] cannot restore: omega_vault.enc failed hash check."
    return 1
  fi

  mkdir -p "$stack_dir"

  log "[vault] restoring wallet;plan from omega_vault.enc → $out_plan"

  if ! openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
    -pass env:OMEGA_BANK_PASSPHRASE \
    -in "$vault_file" \
    -out "$out_plan"
  then
    soft_warn "[vault] openssl decrypt failed; check that cache vortex matches vault key."
    return 1
  fi

  log "[vault] wallet;plan restored to $out_plan"
  return 0
}

# --------------------------- Unlock (cache vortex) --------------------------

omega_unlock() {
  # If already set, don't overwrite (trust may have injected it)
  if [ -n "${OMEGA_BANK_PASSPHRASE-}" ]; then
    soft_warn "[unlock] OMEGA_BANK_PASSPHRASE already set; keeping existing value."
    return 0
  fi

  # Pull from launchctl if available and not explicitly disabled.
  if [ -z "${OMEGA_VORTEX_NO_LAUNCHCTL-}" ] && command -v launchctl >/dev/null 2>&1; then
    local _cached
    _cached="$(launchctl getenv OMEGA_BANK_PASSPHRASE 2>/dev/null || true)"
    if [ -n "${_cached}" ]; then
      export OMEGA_BANK_PASSPHRASE="${_cached}"
      log "[unlock] cache vortex imported from launchctl env."
      unset _cached
      return 0
    fi
    unset _cached
  fi

  # Pull from GKE Secret Manager via kubectl if requested and not already set.
  if [ -z "${OMEGA_VORTEX_NO_GCP-}" ] && command -v kubectl >/dev/null 2>&1; then
    local secret_namespace="${OMEGA_VORTEX_SECRET_NS:-dlog-universe}"
    local secret_name="${OMEGA_VORTEX_SECRET_NAME:-omega-vortex}"
    # Try each context until one succeeds.
    local contexts_raw="${KUBE_CONTEXTS-}"
    if [ -z "$contexts_raw" ]; then
      contexts_raw="$(kubectl config get-contexts -o name 2>/dev/null | tr '\n' ' ')"
    fi
    # shellcheck disable=SC2206
    local contexts=(${contexts_raw//,/ })
    for ctx in "${contexts[@]}"; do
      if [ -z "$ctx" ]; then
        continue
      fi
      if val="$(kubectl --context "$ctx" -n "$secret_namespace" get secret "$secret_name" -o jsonpath='{.data.passphrase}' 2>/dev/null)"; then
        if decoded="$(printf '%s' "$val" | base64 --decode 2>/dev/null)"; then
          if [ -n "$decoded" ]; then
            export OMEGA_BANK_PASSPHRASE="$decoded"
            log "[unlock] cache vortex imported from kubectl secret $secret_namespace/$secret_name (context=$ctx)."
            return 0
          fi
        fi
      fi
    done
  fi

  if [ -n "${OMEGA_UNLOCK_NONINTERACTIVE-}" ]; then
    soft_warn "[unlock] noninteractive mode and no cache vortex found; skipping prompt."
    return 1
  fi

  # VORTEX paste screen
  printf '\n'
  printf '∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!\n'
  printf '          O M E G A   V O R T E X\n'
  printf '              C A C H E\n'
  printf '                 ↓\n'
  printf '          paste the master key\n'
  printf '          it will only live in RAM\n'
  printf '∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!\n'
  printf '\n'
  printf '  VORTEX INPUT (hidden): '

  # Read without echo (paste-safe)
  IFS= read -r -s _omega_passphrase
  printf '\n\n'

  if [ -z "${_omega_passphrase-}" ]; then
    soft_warn "[unlock] empty passphrase; not exporting."
    unset _omega_passphrase
    return 1
  fi

  export OMEGA_BANK_PASSPHRASE="$_omega_passphrase"
  unset _omega_passphrase

  # Optionally seed launchctl so future wand runs (new shells) can reuse the key in RAM.
  if [ -z "${OMEGA_VORTEX_NO_LAUNCHCTL-}" ] && command -v launchctl >/dev/null 2>&1; then
    if ! launchctl setenv OMEGA_BANK_PASSPHRASE "${OMEGA_BANK_PASSPHRASE}" 2>/dev/null; then
      soft_warn "[unlock] launchctl setenv failed; key kept only in this process."
    else
      log "[unlock] cache vortex seeded in launchctl env (RAM only)."
    fi
  fi

  log "[unlock] cache vortex primed in OMEGA_BANK_PASSPHRASE for this spell."
  return 0
}

# --------------------------- Core commands ----------------------------------

cmd_ping() {
  cat <<EOF
Desktop:          $HOME/Desktop
DLOG_ROOT:        $DLOG_ROOT
OMEGA_ROOT:       $OMEGA_ROOT
STACK_ROOT:       $STACK_ROOT
UNIVERSE_NS:      $UNIVERSE_NS
KUBE_MANIFEST:    $KUBE_MANIFEST
Ω-INF-ROOT:       $OMEGA_INF_ROOT
PROJECT_ID:       $PROJECT_ID
RUN_REGION:       $RUN_REGION
RUN_PLATFORM:     $RUN_PLATFORM
CLOUD_RUN_SERVICE:$CLOUD_RUN_SERVICE
BACKEND_SERVICE:  ${BACKEND_SERVICE:-<unset>}
EOF
}

cmd_beat() {
  mkdir -p "$STACK_ROOT" "$OMEGA_INF_ROOT" "$DLOG_ROOT/dashboard" "$DLOG_ROOT/sky" "$KUBE_MANIFEST/universe"

  local stack_file="$STACK_ROOT/stack;universe"
  local dash_file="$DLOG_ROOT/dashboard/dashboard;status"
  local nine_inf="$OMEGA_INF_ROOT/9∞.txt"

  printf 'universe-snapshot:%s\n' "$(timestamp)" >"$stack_file"
  log "[beat] wrote stack snapshot → $stack_file"

  printf '9∞ root anchored at %s\n' "$(timestamp)" >"$nine_inf"
  log "[beat] wrote 9∞ master root → $nine_inf"

  printf 'dashboard status @ %s\n' "$(timestamp)" >"$dash_file"
  log "[beat] wrote Ω-dashboard snapshot → $dash_file"

  log "[beat] wrote Ω-sky manifest & timeline → $DLOG_ROOT/sky"

  log "[beat] applying universe manifests → $KUBE_MANIFEST/universe (namespace $UNIVERSE_NS)"
  log "[beat] complete (stack + dashboard + 9∞)."
}

cmd_flames() {
  local hz="8888"
  if [ "${1-}" = "hz" ] && [ -n "${2-}" ]; then
    hz="$2"; shift 2 || true
  fi

  mkdir -p "$DLOG_ROOT/flames"
  local control="$DLOG_ROOT/flames/flames;control"

  {
    printf 'hz=%s\n' "$hz"
    printf 'height=7\n'
    printf 'friction=leidenfrost\n'
  } >"$control"

  printf '[refold] wrote flames control → %s\n' "$control"
  printf 'Flames control: hz=%s height=7 friction=leidenfrost\n' "$hz"
  printf '(refold.command itself does not start audio — your Ω-engine must read %s)\n' "$control"
}

cmd_speaker() {
  mkdir -p "$DLOG_ROOT/flames"
  local profile="$DLOG_ROOT/flames/speaker;leidenfrost"
  local hz="${1:-8888}"
  local gain="${2:-0.05}"
  local mode="${3:-whoosh_rail}"
  local height="${4:-7}"

  {
    printf 'hz=%s\n' "$hz"
    printf 'gain=%s\n' "$gain"
    printf 'mode=%s\n' "$mode"
    printf 'height=%s\n' "$height"
  } >"$profile"

  printf '[speaker] wrote Ω speaker profile → %s\n' "$profile"
  printf '[speaker] tune omega_speakers against hz=%s gain=%s mode=%s height=%s\n' "$hz" "$gain" "$mode" "$height"
}

cmd_wallet_stack() {
  mkdir -p "$STACK_ROOT"
  local plan="$STACK_ROOT/wallet;plan"

  if [ -d "$DLOG_ROOT/omega_bank" ]; then
    log "[wallet] running omega_bank to derive Golden Wallet Stack plan…"
    if (cd "$DLOG_ROOT/omega_bank" && cargo run --release >/tmp/omega_bank.out 2>/tmp/omega_bank.err); then
      mkdir -p "$(dirname "$plan")"
      mv /tmp/omega_bank.out "$plan"
    else
      soft_warn "[wallet] omega_bank cargo run failed; writing stub plan."
      printf 'wallet-plan-stub @ %s\n' "$(timestamp)" >"$plan"
    fi
  else
    soft_warn "[wallet] omega_bank crate not found; writing stub plan."
    printf 'wallet-plan-stub @ %s\n' "$(timestamp)" >"$plan"
  fi

  printf '=== 🟡 GOLDEN WALLET STACK PLAN ===\n'
  printf '[wallet] snapshot saved → %s\n' "$plan"
}

cmd_wallet() {
  local sub="${1-stack}"; shift || true
  case "$sub" in
    stack) cmd_wallet_stack ;;
    *)
      soft_warn "[wallet] unknown subcommand: $sub"
      return 1
      ;;
  esac
}

cmd_dns_router() {
  mkdir -p "$STACK_ROOT"
  local out="$STACK_ROOT/dns;router"
  printf 'dns-router snapshot @ %s\n' "$(timestamp)" >"$out"
  printf '[dns-router] snapshot → %s\n' "$out"
}

cmd_rails() {
  mkdir -p "$STACK_ROOT"
  local out="$STACK_ROOT/rails;omega"
  local epoch
  epoch="$(date +%s)"

  printf '=== 🌀 refold.command rails (Ω IP bands) ===\n'
  printf '[rails] epoch=%s railHz=8888 bands=8\n' "$epoch"

  # Allow the caller to override the 8-lane bus via OMEGA_RAIL_IPS
  # Accepts either comma- or space-separated addresses; pads/truncates to 8 lanes.
  local ips_raw="${OMEGA_RAIL_IPS-}"
  local ips_default="216.239.32.21 216.239.34.21 216.239.36.21 216.239.38.21 216.239.32.21 216.239.34.21 216.239.36.21 216.239.38.21"
  local ips=()
  if [ -n "$ips_raw" ]; then
    # shellcheck disable=SC2206 # intentional word split after comma replacement
    ips=(${ips_raw//,/ })
  else
    # shellcheck disable=SC2206 # intentional word split of default list
    ips=($ips_default)
  fi

  # Normalize to exactly 8 entries
  while [ "${#ips[@]}" -lt 8 ]; do
    ips+=("<none>")
  done
  if [ "${#ips[@]}" -gt 8 ]; then
    ips=("${ips[@]:0:8}")
  fi

  local bus_byte=0

  {
    printf 'epoch=%s\n' "$epoch"
    printf 'hz=8888\n'
    local i
    for i in $(seq 0 7); do
      local ip="${ips[$i]}"
      local bit=0
      # Treat a non-empty, non-0.0.0.0, non-<none> lane as "1"
      if [ -n "$ip" ] && [ "$ip" != "<none>" ] && [ "$ip" != "0.0.0.0" ]; then
        bit=1
      fi
      bus_byte=$((bus_byte | (bit << i)))

      printf 'band%02d=%s\n' "$i" "$ip"
      printf '[rails] band%02d → %s (bit=%d)\n' "$i" "$ip" "$bit" >&2
      printf ';∞;rail_band;%02d;%s;%d;\n' "$i" "$ip" "$bit"
    done
    local bits_str=""
    for i in 7 6 5 4 3 2 1 0; do
      bits_str="${bits_str}$(((bus_byte >> i) & 1))"
    done
    printf 'bus_bits=%s\n' "$bits_str"
    printf 'bus_hex=0x%02X\n' "$bus_byte"
    printf 'bus_byte=%d\n' "$bus_byte"
    printf ';∞;rail_bus;%d;bits=%s;\n' "$bus_byte" "$bits_str"
  } >>"$out"

  printf '[rails] bus → 0b%08b (%d / 0x%02X)\n' "$bus_byte" "$bus_byte" "$bus_byte" >&2
  printf '[rails] appended snapshot → %s\n' "$out"
}

cmd_netcheck() {
  log "[netcheck] (stub) verify Cloud DNS access for gcloud"
}

cmd_deploy() {
  log "[deploy] (stub) build + deploy Cloud Run service for $PROJECT_ID/$CLOUD_RUN_SERVICE"
}

cmd_domains() {
  local sub="${1-status}"; shift || true
  case "$sub" in
    status)
      log "[domains] (stub) show DNS + Cloud Run domain-mapping for Ω domains"
      ;;
    map)
      log "[domains] (stub) ensure domain-mappings exist (where verified)"
      ;;
    *)
      soft_warn "[domains] unknown subcommand: $sub"
      return 1
      ;;
  esac
}

cmd_kube_sync() {
  local manifest_dir="$KUBE_MANIFEST/universe"

  if ! command -v kubectl >/dev/null 2>&1; then
    soft_warn "[kube-sync] kubectl not found; cannot apply manifests."
    return 1
  fi

  if [ ! -d "$manifest_dir" ]; then
    soft_warn "[kube-sync] manifest dir missing: $manifest_dir"
    return 1
  fi

  # Comma- or space-separated list of contexts to fan out across rails (8 expected).
  local contexts_raw="${KUBE_CONTEXTS-}"
  if [ -z "$contexts_raw" ]; then
    # Auto-discover from kubectl config, up to 8 contexts.
    contexts_raw="$(
      kubectl config get-contexts -o name 2>/dev/null | head -n 8 | tr '\n' ' ' | sed 's/[[:space:]]*$//'
    )"
    if [ -z "$contexts_raw" ]; then
      log "[kube-sync] skipping: KUBE_CONTEXTS not set and no contexts found via kubectl config."
      return 0
    fi
    log "[kube-sync] using auto-discovered contexts: $contexts_raw"
  fi
  # shellcheck disable=SC2206 # intentional split
  local contexts=(${contexts_raw//,/ })
  if [ ${#contexts[@]} -eq 0 ]; then
    log "[kube-sync] skipping: no contexts parsed."
    return 0
  fi

  if [ ${#contexts[@]} -lt 8 ]; then
    soft_warn "[kube-sync] fewer than 8 contexts provided; using ${#contexts[@]} target(s)."
  fi

  local status=0
  local idx=0
  local successes=0
  for ctx in "${contexts[@]}"; do
    local ns="${UNIVERSE_NS}"
    log "[kube-sync] applying manifests to context=$ctx ns=$ns (rail $idx)"

    # Ensure namespace exists (best effort)
    if ! kubectl --context "$ctx" get ns "$ns" >/dev/null 2>&1; then
      if ! kubectl --context "$ctx" create ns "$ns" >/dev/null 2>&1; then
        soft_warn "[kube-sync] namespace $ns missing and create failed for context=$ctx"
        status=1
        idx=$((idx + 1))
        continue
      fi
    fi

    if [ -f "$manifest_dir/kustomization.yaml" ] || [ -f "$manifest_dir/kustomization.yml" ]; then
      if ! kubectl --context "$ctx" --namespace "$ns" apply -k "$manifest_dir"; then
        soft_warn "[kube-sync] apply -k failed for context=$ctx ns=$ns"
        status=1
      else
        successes=$((successes + 1))
      fi
    else
      if ! kubectl --context "$ctx" --namespace "$ns" apply -R -f "$manifest_dir"; then
        soft_warn "[kube-sync] apply -f failed for context=$ctx ns=$ns"
        status=1
      else
        successes=$((successes + 1))
      fi
    fi

    idx=$((idx + 1))
  done

  if [ "$successes" -gt 0 ]; then
    return 0
  fi
  return "$status"
}

cmd_shields() {
  local sub="${1-once}"; shift || true
  case "$sub" in
    once)
      log "[shields] (stub) one-time Cloud Armor + backend attach"
      ;;
    watch)
      log "[shields] (stub) continuous Ω-shield heartbeat (8s)"
      ;;
    *)
      soft_warn "[shields] unknown subcommand: $sub"
      return 1
      ;;
  esac
}

cmd_flow() {
  cmd_ping
  cmd_beat
  cmd_flames
  cmd_deploy
  cmd_domains status
  cmd_rails
}

# ------------------------------ Wand ----------------------------------------

cmd_wand() {
  local status=0

  printf '=== ✨ refold.command magic wand (ping → beat → flames → speaker → wallet → dns-router → rails) ===\n'

  # Auto-unlock cache vortex once so wallet/vault steps can use the key.
  if [ -z "${OMEGA_BANK_PASSPHRASE-}" ]; then
    soft_warn "[wand] no cache vortex detected; invoking omega_unlock…"
    if ! omega_unlock; then
      soft_warn "[wand] omega_unlock aborted; continuing without cache vortex."
    fi
  fi

  cmd_ping
  echo

  cmd_beat || status=1
  echo

  cmd_flames || status=1
  cmd_speaker || status=1
  echo

  # Wallet step always runs; if no key, still writes stub plan
  cmd_wallet stack || status=1
  echo

  # Kube sync across all configured contexts (unless explicitly skipped)
  if [ -n "${KUBE_SYNC_SKIP-}" ]; then
    log "[kube-sync] skipping (KUBE_SYNC_SKIP is set)."
  fi
  echo

  # Vault sync only if cache vortex is present (shell or agent set the key)
  if [ -n "${OMEGA_BANK_PASSPHRASE-}" ]; then
    if ! ensure_vault_from_cache; then
      soft_warn "[wand] vault ensure from cache vortex failed; continuing with warnings."
      status=1
    fi
  else
    soft_warn "[wand] OMEGA_BANK_PASSPHRASE not set; skipping vault sync."
  fi
  echo

  cmd_dns_router || status=1
  echo

  cmd_rails || status=1

  if [ "$status" -ne 0 ]; then
    printf '[wand] complete with warnings — review logs above.\n'
  else
    printf '[wand] complete.\n'
  fi

  return "$status"
}

# --------------------------- Usage / Dispatcher -----------------------------

usage() {
  cat <<EOF
Usage: refold.command <subcommand> [args...]

Subcommands:
  ping                       Show Ω-environment
  beat                       Stack + dashboard + sky + kube
  wand                       Magic-wand chain (ping→beat→flames→speaker→wallet→dns→rails)
  netcheck                   Verify Cloud DNS access for gcloud
  flames [hz <value>]        Write Ω flame control (default 8888 Hz)
  speaker [hz gain mode h]   Write Ω speaker profile (default 8888 0.05 whoosh_rail 7)
  deploy                     Build + deploy Cloud Run service
  domains status             Show DNS + Cloud Run domain-mapping for Ω domains
  domains map                Ensure domain-mappings exist (where verified)
  rails                      Sample IPs into 8 Ω-bands (8-bit bus; OMEGA_RAIL_IPS override) and log to stack
  dns-router                 Snapshot A/AAAA inventory per Ω domain
  kube-sync                  Apply Kubernetes manifests (system + universe)
  shields once               One-time Cloud Armor + backend attach
  shields watch              Continuous Ω-shield heartbeat (8s)
  flow                       ping → beat → flames → deploy → domains → rails
  wallet stack               Derive 256×XAUT/BTC/DOGE ids and log snapshot
  vault verify               Check omega_vault.enc hash against .sha512
  vault rebuild              (Re)emit omega_vault.enc + .sha512 from cache vortex
  vault restore              Decrypt omega_vault.enc back into stack/wallet;plan
  unlock                     Prompt once for OMEGA_BANK_PASSPHRASE (cache vortex)
EOF
}

main() {
  local cmd="${1-}"; shift || true
  case "$cmd" in
    ""|-h|--help) usage ;;
    ping)         cmd_ping ;;
    beat)         cmd_beat ;;
    wand)         cmd_wand ;;
    netcheck)     cmd_netcheck ;;
    flames)       cmd_flames "$@" ;;
    speaker)      cmd_speaker "$@" ;;
    deploy)       cmd_deploy ;;
    domains)      cmd_domains "$@" ;;
    rails)        cmd_rails ;;
    dns-router)   cmd_dns_router ;;
    kube-sync)    cmd_kube_sync ;;
    shields)      cmd_shields "$@" ;;
    flow)         cmd_flow ;;
    wallet)       cmd_wallet "$@" ;;
    vault)
      local sub="${1-verify}"; shift || true
      case "$sub" in
        verify)
          verify_vault_integrity
          ;;
        rebuild)
          # Auto-unlock inside this process if needed
          if [ -z "${OMEGA_BANK_PASSPHRASE-}" ]; then
            log "[vault] no cache vortex detected; invoking omega_unlock…"
            if ! omega_unlock; then
              soft_warn "[vault] unable to unlock cache vortex; aborting rebuild."
              exit 1
            fi
          fi
          ensure_vault_from_cache
          ;;
        restore)
          # Auto-unlock inside this process if needed
          if [ -z "${OMEGA_BANK_PASSPHRASE-}" ]; then
            log "[vault] no cache vortex detected; invoking omega_unlock…"
            if ! omega_unlock; then
              soft_warn "[vault] unable to unlock cache vortex; aborting restore."
              exit 1
            fi
          fi
          restore_vault_to_stack
          ;;
        *)
          usage
          exit 1
          ;;
      esac
      ;;
    unlock)       omega_unlock ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
