use crate::model::{BlockEvent, BlockLedger, ChunkSnapshot};
use google_cloud_storage::client::{Client, ClientConfig};
use google_cloud_storage::http::objects::download::Range;
use google_cloud_storage::http::objects::get::GetObjectRequest;
use google_cloud_storage::http::objects::upload::{Media, UploadObjectRequest, UploadType};
use google_cloud_storage::http::Error as GcsError;
use hyper::http::StatusCode;
use serde::{de::DeserializeOwned, Serialize};
use std::sync::Arc;

#[derive(Clone)]
pub struct OmegaStorage {
    client: Arc<Client>,
    bucket: String,
}

impl OmegaStorage {
    pub async fn new_from_env() -> anyhow::Result<Self> {
        let bucket = std::env::var("OMEGA_BUCKET")?;
        let config = ClientConfig::default().with_auth().await?;
        let client = Client::new(config);
        Ok(Self {
            client: Arc::new(client),
            bucket,
        })
    }

    fn key_for_player(player_uuid: &str) -> String {
        format!("sim;players;{};state.json", player_uuid)
    }

    fn key_for_chunk(cx: i64, cz: i64) -> String {
        format!("world;chunks;{};{}.json", cx, cz)
    }

    fn key_for_block_ledger(cx: i64, cz: i64) -> String {
        format!("ledger;blocks;{};{}.json", cx, cz)
    }

    pub async fn load_json<T: DeserializeOwned>(&self, key: &str) -> anyhow::Result<Option<T>> {
        let req = GetObjectRequest {
            bucket: self.bucket.clone(),
            object: key.to_string(),
            ..Default::default()
        };

        let bytes = match self
            .client
            .download_object(&req, &Range::default())
            .await
        {
            Ok(data) => data,
            Err(GcsError::Response(err)) if err.code == 404 => return Ok(None),
            Err(GcsError::HttpClient(err)) if err.status() == Some(StatusCode::NOT_FOUND) => {
                return Ok(None)
            }
            Err(e) => return Err(e.into()),
        };

        let value = serde_json::from_slice(&bytes)?;
        Ok(Some(value))
    }

    pub async fn save_json<T: Serialize>(&self, key: &str, value: &T) -> anyhow::Result<()> {
        let bytes = serde_json::to_vec(value)?;
        let mut media = Media::new(key.to_string());
        media.content_type = "application/json".into();
        media.content_length = Some(bytes.len() as u64);
        let upload_type = UploadType::Simple(media);
        let req = UploadObjectRequest {
            bucket: self.bucket.clone(),
            ..Default::default()
        };
        self.client.upload_object(&req, bytes, &upload_type).await?;
        Ok(())
    }

    pub async fn load_player_state<T: DeserializeOwned>(
        &self,
        player_uuid: &str,
    ) -> anyhow::Result<Option<T>> {
        let key = Self::key_for_player(player_uuid);
        self.load_json(&key).await
    }

    pub async fn save_player_state<T: Serialize>(
        &self,
        player_uuid: &str,
        state: &T,
    ) -> anyhow::Result<()> {
        let key = Self::key_for_player(player_uuid);
        self.save_json(&key, state).await
    }

    pub async fn load_chunk(&self, cx: i64, cz: i64) -> anyhow::Result<ChunkSnapshot> {
        let key = Self::key_for_chunk(cx, cz);
        let chunk = self
            .load_json::<ChunkSnapshot>(&key)
            .await?
            .unwrap_or_else(|| ChunkSnapshot {
                cx,
                cz,
                ..ChunkSnapshot::default()
            });
        Ok(chunk)
    }

    pub async fn save_chunk(&self, chunk: &ChunkSnapshot) -> anyhow::Result<()> {
        let key = Self::key_for_chunk(chunk.cx, chunk.cz);
        self.save_json(&key, chunk).await
    }

    pub async fn append_block_events(
        &self,
        cx: i64,
        cz: i64,
        events: &[BlockEvent],
    ) -> anyhow::Result<()> {
        if events.is_empty() {
            return Ok(());
        }
        let key = Self::key_for_block_ledger(cx, cz);
        let mut ledger = self
            .load_json::<BlockLedger>(&key)
            .await?
            .unwrap_or_default();
        ledger.events.extend_from_slice(events);
        // Keep a modest window so the ledger does not grow unbounded.
        const MAX_EVENTS: usize = 512;
        if ledger.events.len() > MAX_EVENTS {
            let drop = ledger.events.len() - MAX_EVENTS;
            ledger.events.drain(0..drop);
        }
        self.save_json(&key, &ledger).await
    }
}
