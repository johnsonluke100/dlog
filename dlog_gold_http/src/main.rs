use axum::{
    response::Html,
    routing::get,
    Router,
};
use std::{env, net::SocketAddr};
use tokio::net::TcpListener;

async fn root() -> Html<&'static str> {
    Html(r#"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>DLOG.GOLD — Big Bank, Legally Rich</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      body {
        margin: 0;
        padding: 0;
        font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
        display: flex;
        min-height: 100vh;
        align-items: center;
        justify-content: center;
        background: radial-gradient(circle at top, #111827 0, #020617 55%, #000 100%);
        color: #e5e7eb;
      }
      .card {
        max-width: 720px;
        padding: 2.5rem;
        border-radius: 1.5rem;
        background: rgba(15,23,42,0.9);
        box-shadow: 0 35px 120px rgba(0,0,0,0.8);
        border: 1px solid rgba(148,163,184,0.25);
      }
      h1 {
        font-size: 2rem;
        margin: 0 0 0.75rem;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: #fbbf24;
      }
      .badge {
        display: inline-flex;
        align-items: center;
        gap: 0.4rem;
        border-radius: 999px;
        padding: 0.2rem 0.75rem;
        font-size: 0.75rem;
        background: rgba(55,65,81,0.9);
        color: #e5e7eb;
        margin-bottom: 0.75rem;
      }
      .badge-dot {
        width: 8px;
        height: 8px;
        border-radius: 999px;
        background: #22c55e;
        box-shadow: 0 0 10px #22c55e;
      }
      p {
        margin: 0.35rem 0;
        line-height: 1.5;
        font-size: 0.95rem;
        color: #cbd5f5;
      }
      .hook {
        margin-top: 1rem;
        font-weight: 600;
        color: #f97316;
      }
      .cta-row {
        margin-top: 1.5rem;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        align-items: center;
      }
      .btn {
        border-radius: 999px;
        padding: 0.55rem 1.25rem;
        font-size: 0.9rem;
        border: none;
        cursor: pointer;
        background: linear-gradient(135deg, #22c55e, #fbbf24);
        color: #020617;
        font-weight: 700;
        letter-spacing: 0.05em;
        text-transform: uppercase;
      }
      .chip {
        padding: 0.3rem 0.8rem;
        border-radius: 999px;
        font-size: 0.8rem;
        border: 1px solid rgba(148,163,184,0.5);
        color: #e5e7eb;
        background: rgba(15,23,42,0.7);
      }
      .footer {
        margin-top: 1.5rem;
        font-size: 0.75rem;
        color: #64748b;
      }
    </style>
  </head>
  <body>
    <main class="card">
      <div class="badge">
        <span class="badge-dot"></span>
        DLOG.GOLD • MONEY MACHINE ONLINE
      </div>
      <h1>BIG BANK • LEGALLY RICH</h1>
      <p>Big bank, big bank, yeah I’m legally rich — walk in the bank and walk out lit. Credit on 10, that’s a powerful lift.</p>
      <p>No scams here — name too clean. Everything legit, everything structured, everything documented.</p>
      <p>We don’t get business just to make money. We get money first, then the business start running.</p>
      <p>Generational wealth, the whole team coming. Leverage that bag, now the bank keep drummin.</p>
      <p>Lines of credit, LOCs, C-Corp moves. Turn one loan into a whole new system. Turn one play into a whole new mission.</p>
      <p class="hook">This is not financial advice — this is financial <strong>literacy</strong> in motion. You are the money manager now.</p>

      <div class="cta-row">
        <button class="btn" type="button">ENTER DLOG UNIVERSE</button>
        <span class="chip">No scams • No shortcuts • All gas</span>
      </div>

      <div class="footer">
        v0.1.0 — Rust gateway on dlog.gold • Next: decks, flows, and live training.
      </div>
    </main>
  </body>
</html>
"#)
}

#[tokio::main]
async fn main() {
    // Cloud Run injects PORT; default to 8080 for local runs
    let port: u16 = env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);

    let app = Router::new().route("/", get(root));

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!("[dlog.gold] Rust HTTP gateway listening on {addr}");
    println!("[dlog.gold] ready for bank-level vibes…");

    let listener = TcpListener::bind(addr)
        .await
        .expect("failed to bind TCP listener");

    if let Err(err) = axum::serve(listener, app).await {
        eprintln!("[dlog.gold] server error: {err}");
    }
}
