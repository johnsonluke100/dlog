# Dockerfile at ~/Desktop/dlog
#
# Builds the `api` binary via a multi-stage build and runs it on a slim base.

# 1. Build stage
FROM rust:1.81 as builder

WORKDIR /usr/src/dlog

# Copy workspace manifests and sources
COPY Cargo.toml rust-toolchain.toml ./
COPY dlog.toml ./dlog.toml
COPY spec ./spec
COPY corelib ./corelib
COPY api ./api

# Build the `api` crate in release mode
RUN cargo build --release -p api

# 2. Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled binary and config from build stage
COPY --from=builder /usr/src/dlog/target/release/api /app/api
COPY --from=builder /usr/src/dlog/dlog.toml /app/dlog.toml

EXPOSE 8080

CMD ["/app/api"]
