# Cloud Run (HTTP/3) Deployment

Google Cloud Run terminates TLS/QUIC for us, so simply deploying the `dlog_gold_http` binary there makes the public endpoint speak HTTP/3 automatically. This guide targets project `dlog-gold`, region `us-east1`, and service name `api`.

## Prerequisites

- Google Cloud CLI (`gcloud`) installed and authenticated: `gcloud auth login`
- Project + region defaults:
  ```bash
  gcloud config set project dlog-gold
  gcloud config set run/region us-east1
  gcloud config set run/platform managed
  ```
- Enable necessary APIs once:
  ```bash
  gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com
  ```
- Optional Artifact Registry repo (if you want to manage images yourself):
  ```bash
  gcloud artifacts repositories create dlog \
    --repository-format docker \
    --location us-east1
  ```

## Deploy

For the quickest path, run the helper script from the repo root:
```bash
./cloud.command deploy
```
It uses Cloud Build’s buildpacks (`gcloud run deploy --source .`), publishes the container, and deploys it as `api` in `us-east1`.

To run the same commands manually:
```bash
gcloud run deploy api \
  --source . \
  --region us-east1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8080
```

Cloud Run prints a URL such as `https://api-xyz-ue.a.run.app`. The platform handles TLS certificates, HTTP/2, and HTTP/3 negotiation automatically.

## Verify HTTP/3

Use a curl build with QUIC support (macOS `brew install curl --with-quiche`, Linux `apt install curl` on recent distros):
```bash
curl --http3 -I https://api-xyz-ue.a.run.app/health
```
You should see a `HTTP/3 200` response plus headers like `alt-svc: h3=":443"; ma=2592000`. Google terminates QUIC at the edge, so no extra server-side configuration is necessary beyond exposing port 8080.
