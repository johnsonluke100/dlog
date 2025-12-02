# Repository Guidelines

## Project Structure & Module Organization
- Rust workspace at the repo root (`Cargo.toml`, `rust-toolchain.toml`, `dlog.toml` config).
- Core crates: `spec` (public types), `corelib` (universe logic), `core` (coordination), `omega` (Leidenfrost engine), `sky` (slideshow timeline), `api` (Axum HTTP API), `dlog_gold_http` (HTTP-4 gateway), `dlog_http4_client` (client prototype), `omega_bank`, and `presence_service`.
- Orchestration scripts live at the root: `refold.command` (one-shot tasks), `wand.loop.command` (8s loop), `cloud.command` (Cloud Run deploy), plus launcher helpers (`dlog.command`, `unfold.command`).
- Generated snapshots and artifacts land in `stack/`, `flames/`, `dashboard/`, and `∞/`; Kubernetes manifests are in `kube/` and `k8s/`; docs in `docs/`.

## Build, Test, and Development Commands
- `cargo build --workspace --all-targets` — compile everything with the pinned toolchain.
- `cargo test --workspace` — run crate tests; narrow with `-p <crate>` when iterating.
- `cargo fmt --all` and `cargo clippy --workspace --all-targets` before pushing.
- Run services locally with `cargo run -p api` or `cargo run -p dlog_gold_http`; most scripts assume port 8888/8080 defaults.
- Automation: `./refold.command wand` runs the ping→beat→flames→speaker→wallet→dns→rails chain; `./refold.command beat` for a lighter sync; `./cloud.command deploy` publishes to Cloud Run.
- Wallet/vault actions require `OMEGA_BANK_PASSPHRASE` in the environment; never commit secrets or derived files.

## Coding Style & Naming Conventions
- Rust 2021, 4-space indent, snake_case for functions/modules, PascalCase for types, SCREAMING_SNAKE_CASE for constants.
- Prefer small, pure helpers; keep log messages concise and prefixed (e.g., `[wand]`, `[vault]`).
- Add doc comments for public items and terse comments only where intent is non-obvious.

## Testing Guidelines
- Use standard Rust tests inside modules (`mod tests`) or `tests/` integration files per crate.
- For APIs, add request/response coverage in the owning crate (e.g., `api`, `dlog_gold_http`); include auth and error paths.
- Run `cargo test -p <crate>` before commits; for changes touching multiple crates, run the full workspace suite.

## Commit & Pull Request Guidelines
- Follow the existing history pattern: short, imperative messages with optional scope (e.g., `feat: add http4 client prototype`, `fix: bank plan guard`, `gold` for release bumps).
- PRs should include: what changed, why, tests/commands run, and any config or env vars required (`OMEGA_TICK_TOKEN`, `PRESENCE_BASE_URL`, etc.). Attach sample responses or screenshots when adjusting HTTP surfaces or dashboards.
- Avoid committing generated snapshots (`stack/`, `flames/`, `∞/`) unless explicitly requested.
