use std::io::{Read, Write};
use std::net::TcpListener;
use std::thread;

/// Minimal HTTP 1.1 server for dlog.gold (Rust only).
/// Cloud Run will set $PORT; we listen on 0.0.0.0:PORT and answer every request.
fn main() -> std::io::Result<()> {
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{}", port);

    println!("[dlog.gold] Rust HTTP gateway listening on {}", addr);

    let listener = TcpListener::bind(&addr)?;
    println!("[dlog.gold] ready for bank-level vibes…");

    for stream in listener.incoming() {
        match stream {
            Ok(mut stream) => {
                thread::spawn(move || {
                    let mut buf = [0u8; 1024];
                    let _ = stream.read(&mut buf);

                    // This is the public face of dlog.gold for now:
                    let body = concat!(
                        "big bank big bank big bank. i'm legally rich.\n",
                        "dlog.gold · Rust-only Ω-endpoint online.\n",
                        "we do not use python anymore.\n",
                        "we do not use javascript.\n",
                        "we rotate timing rail @ 8888 Hz in the backend.\n",
                    );

                    let response = format!(
                        "HTTP/1.1 200 OK\r\n\
                         Content-Type: text/plain; charset=utf-8\r\n\
                         Content-Length: {}\r\n\
                         Connection: close\r\n\
                         \r\n\
                         {}",
                        body.len(),
                        body
                    );

                    let _ = stream.write_all(response.as_bytes());
                    let _ = stream.flush();
                });
            }
            Err(e) => {
                eprintln!("[dlog.gold] connection error: {e}");
            }
        }
    }

    Ok(())
}

