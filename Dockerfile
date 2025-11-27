# Dockerfile – build a dlog-api container (Rust-only spine, no JS/Java/Python).

# Builder image
FROM rust:1.80 as builder

WORKDIR /app

# Copy the whole workspace; Docker cache will reuse build layers when possible.
COPY . .

# Build the dlog-api binary in release mode.
RUN cargo build --release -p dlog-api

# Runtime image – thin Debian with just the binary.
FROM debian:12-slim

# Minimal runtime deps.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled binary from builder stage.
COPY --from=builder /app/target/release/dlog-api /usr/local/bin/dlog-api

# Default runtime env (overridable).
ENV DLOG_RUNTIME_MODE=container_supabase
ENV DLOG_BIND=0.0.0.0
ENV DLOG_PORT=8888

# Optional Supabase envs can be injected by the orchestrator.
ENV SUPABASE_URL=""
ENV SUPABASE_ANON_KEY=""

EXPOSE 8888

# Rust spine, no script glue: just run the binary.
CMD [ "dlog-api" ]
