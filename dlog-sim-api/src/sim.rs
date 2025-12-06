use crate::model::{InputEvent, RenderCommand, TickRequest, TickResponse};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize, Default)]
pub struct PlayerState {
    pub universe_tick: u64,
    pub omega_x: f64,
    pub omega_y: f64,
    pub omega_z: f64,
}

pub fn advance(mut state: PlayerState, req: &TickRequest) -> (PlayerState, TickResponse) {
    state.universe_tick = state.universe_tick.wrapping_add(1);

    let mut interact_title = None;

    for event in &req.inputs {
        match event {
            InputEvent::Move { dx, dy, dz } => {
                state.omega_x += dx;
                state.omega_y += dy;
                state.omega_z += dz;
            }
            InputEvent::Jump => {}
            InputEvent::Interact { target_id } => {
                if let Some(id) = target_id {
                    interact_title = Some(format!("Interacted with {id}"));
                }
            }
        }
    }

    let mut render = vec![
        RenderCommand::PlaceArmorStand {
            id: "as-origin".into(),
            x: 0.0,
            y: 64.0,
            z: 0.0,
            yaw: 0.0,
            pitch: 0.0,
        },
        RenderCommand::MoveArmorStand {
            id: format!("player-{}", req.player_uuid),
            x: req.position.x,
            y: req.position.y,
            z: req.position.z,
            yaw: req.position.yaw,
            pitch: req.position.pitch,
        },
        RenderCommand::Title {
            text: format!(
                "Ω tick {} (local {})",
                state.universe_tick, req.local_tick
            ),
        },
    ];

    if let Some(text) = interact_title {
        render.push(RenderCommand::Title { text });
    }

    let resp = TickResponse {
        universe_tick: state.universe_tick,
        render,
        chunks: Vec::new(),
    };

    (state, resp)
}
