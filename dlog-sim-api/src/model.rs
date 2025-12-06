use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct TickRequest {
    pub player_uuid: String,
    pub local_tick: u64,
    pub position: Position,
    #[serde(default)]
    pub inputs: Vec<InputEvent>,
    #[serde(default)]
    pub block_updates: Vec<BlockUpdate>,
}

#[derive(Debug, Serialize)]
pub struct TickResponse {
    pub universe_tick: u64,
    pub render: Vec<RenderCommand>,
    #[serde(default)]
    pub chunks: Vec<ChunkSnapshot>,
}

#[derive(Debug, Deserialize)]
pub struct Position {
    pub x: f64,
    pub y: f64,
    pub z: f64,
    pub yaw: f32,
    pub pitch: f32,
}

#[derive(Debug, Deserialize)]
#[serde(tag = "type")]
pub enum InputEvent {
    Move { dx: f64, dy: f64, dz: f64 },
    Jump,
    Interact { target_id: Option<String> },
}

#[derive(Debug, Deserialize, Clone)]
pub struct BlockUpdate {
    pub x: i64,
    pub y: i64,
    pub z: i64,
    pub block: String,
    #[serde(default)]
    pub action: BlockAction,
}

#[derive(Debug, Serialize, Deserialize, Clone, Copy)]
#[serde(rename_all = "lowercase")]
pub enum BlockAction {
    Place,
    Break,
}

impl Default for BlockAction {
    fn default() -> Self {
        BlockAction::Place
    }
}

#[derive(Debug, Serialize)]
#[serde(tag = "type")]
pub enum RenderCommand {
    PlaceArmorStand {
        id: String,
        x: f64,
        y: f64,
        z: f64,
        yaw: f32,
        pitch: f32,
    },
    MoveArmorStand {
        id: String,
        x: f64,
        y: f64,
        z: f64,
        yaw: f32,
        pitch: f32,
    },
    #[allow(dead_code)]
    RemoveArmorStand {
        id: String,
    },
    Title {
        text: String,
    },
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct ChunkSnapshot {
    pub cx: i64,
    pub cz: i64,
    #[serde(default)]
    pub version: u64,
    #[serde(default)]
    pub blocks: Vec<BlockState>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct BlockState {
    pub x: i64,
    pub y: i64,
    pub z: i64,
    pub block: String,
    pub last_tick: u64,
}

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct BlockLedger {
    #[serde(default)]
    pub events: Vec<BlockEvent>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct BlockEvent {
    pub tick: u64,
    pub x: i64,
    pub y: i64,
    pub z: i64,
    pub block: String,
    pub action: BlockAction,
}
