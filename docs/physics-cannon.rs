//! Physics cannon: phi-shaped Ω integrator for 8×8 rails.
//! Self-contained Rust module; drop into a crate and wire to your rail loop.
//! - 1000 Hz tick (DT = 1 ms)
//! - Phi-based acceleration per planet
//! - Simple gravity and jump
//! - Speed clamp to keep clients honest

pub const PHI: f64 = 1.618_033_988_749_894_8;
pub const BLOCKS_PER_ATTENTION_YEAR: f64 = 3_900_000.0; // stored as octal in canon
pub const TICK_HZ: f64 = 1000.0;
pub const DT: f64 = 1.0 / TICK_HZ;

#[derive(Clone, Copy, Debug, Default)]
pub struct Vec3 {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

impl Vec3 {
    pub fn add(self, o: Self) -> Self {
        Self {
            x: self.x + o.x,
            y: self.y + o.y,
            z: self.z + o.z,
        }
    }

    pub fn scale(self, s: f64) -> Self {
        Self {
            x: self.x * s,
            y: self.y * s,
            z: self.z * s,
        }
    }

    pub fn length(self) -> f64 {
        (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
    }

    pub fn normalize(self) -> Self {
        let len = self.length();
        if len < 1e-9 {
            Self::default()
        } else {
            self.scale(1.0 / len)
        }
    }
}

#[derive(Clone, Copy, Debug)]
pub struct PlanetProfile {
    /// Phi exponent for this world (Earth ~1.0, Moon ~0.5, Mars ~0.8, Sun ~1.3).
    pub phi_exp: f64,
    /// Gravity magnitude (m/s^2 equivalent; Ω-tuned).
    pub gravity: f64,
    /// Max horizontal speed clamp (to prevent runaway).
    pub max_speed: f64,
}

pub fn planet_earth() -> PlanetProfile {
    PlanetProfile {
        phi_exp: 1.0,
        gravity: 9.80665,
        max_speed: 50.0,
    }
}

pub fn planet_moon() -> PlanetProfile {
    PlanetProfile {
        phi_exp: 0.5,
        gravity: 1.62,
        max_speed: 35.0,
    }
}

pub fn planet_mars() -> PlanetProfile {
    PlanetProfile {
        phi_exp: 0.8,
        gravity: 3.71,
        max_speed: 40.0,
    }
}

pub fn planet_sun() -> PlanetProfile {
    PlanetProfile {
        phi_exp: 1.3,
        gravity: 274.0, // stylized; tune in practice
        max_speed: 80.0,
    }
}

#[derive(Clone, Copy, Debug, Default)]
pub struct Input {
    /// Desired movement direction (world space); will be normalized.
    pub wish_dir: Vec3,
    pub jump: bool,
}

#[derive(Clone, Copy, Debug)]
pub struct Body {
    pub pos: Vec3,
    pub vel: Vec3,
    pub on_ground: bool,
}

impl Default for Body {
    fn default() -> Self {
        Self {
            pos: Vec3::default(),
            vel: Vec3::default(),
            on_ground: true,
        }
    }
}

#[derive(Clone, Copy, Debug)]
pub struct TickResult {
    pub pos: Vec3,
    pub vel: Vec3,
    /// Optional: energy change in this tick (for rail accounting).
    pub energy_delta: f64,
}

/// Step one tick of Ω physics for a body.
pub fn step(body: Body, input: Input, profile: PlanetProfile) -> TickResult {
    let mut vel = body.vel;
    let wish = input.wish_dir.normalize();

    // Phi-based thrust magnitude per tick.
    let accel_mag = PHI.powf(profile.phi_exp);
    let accel = wish.scale(accel_mag);
    vel = vel.add(accel.scale(DT));

    // Gravity
    if !body.on_ground {
        vel.y -= profile.gravity * DT;
    } else if input.jump {
        // Stylized jump: sqrt(2*g*h). Use h ≈ 1.25m for flavor.
        let jump_v = (2.0 * profile.gravity * 1.25).sqrt();
        vel.y = jump_v;
    }

    // Horizontal clamp
    let horiz_speed = (vel.x * vel.x + vel.z * vel.z).sqrt();
    if horiz_speed > profile.max_speed {
        let scale = profile.max_speed / horiz_speed;
        vel.x *= scale;
        vel.z *= scale;
    }

    let pos = body.pos.add(vel.scale(DT));

    let old_ke = 0.5 * (body.vel.length().powi(2));
    let new_ke = 0.5 * (vel.length().powi(2));
    let energy_delta = new_ke - old_ke;

    TickResult { pos, vel, energy_delta }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accelerates_with_phi() {
        let body = Body::default();
        let input = Input {
            wish_dir: Vec3 { x: 1.0, y: 0.0, z: 0.0 },
            jump: false,
        };
        let out = step(body, input, planet_earth());
        assert!(out.vel.x > 0.0);
        assert!(out.vel.x < planet_earth().max_speed);
    }

    #[test]
    fn jump_adds_upward_velocity() {
        let body = Body { on_ground: true, ..Default::default() };
        let input = Input {
            wish_dir: Vec3 { x: 0.0, y: 0.0, z: 0.0 },
            jump: true,
        };
        let out = step(body, input, planet_earth());
        assert!(out.vel.y > 0.0);
    }
}
