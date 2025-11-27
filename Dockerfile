# Multi-stage build for dlog-api
FROM rust:1.80 AS builder

WORKDIR /app
COPY . .

# Build the API binary
RUN cargo build --release -p dlog-api

FROM debian:bookworm-slim

RUN useradd -m dlog
USER dlog

WORKDIR /app

COPY --from=builder /app/target/release/dlog-api /usr/local/bin/dlog-api

ENV RUST_LOG=info

EXPOSE 8888

CMD ["dlog-api"]
