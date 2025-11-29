# 1) Build stage: compile the dlog_gold_http crate
FROM rust:1.82-bullseye AS builder

WORKDIR /app

# Copy workspace manifest files
COPY Cargo.toml Cargo.lock ./

# Copy the whole workspace (gcloudignore will keep it light)
COPY . .

# Build only the HTTP gateway crate
RUN cargo build --release -p dlog_gold_http

# 2) Runtime stage: small Debian image with just the binary
FROM debian:bullseye-slim

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary from the builder image
COPY --from=builder /app/target/release/dlog_gold_http /app/dlog_gold_http

# Cloud Run will inject $PORT; default is 8080
ENV PORT=8080

EXPOSE 8080

CMD ["./dlog_gold_http"]
