//! SkyLighting logic for the Ω universe.
//!
//! This is the Rust spiritual successor of your Java `sky` plugin:
//! - SlideshowScheduler  → SkyTimeline
//! - ProcessedImage      → SkySlideRef (in `dlog-spec`)
//! - SkyRenderer/RayTrace→ we just pick frames for now; ray maths can come later.

use dlog_spec::{SkyShowConfig, SkySlideRef};

/// Runtime representation of a looping sky timeline.
#[derive(Debug, Clone)]
pub struct SkyTimeline {
    show: SkyShowConfig,
    total_duration_ticks: u64,
}

impl SkyTimeline {
    /// Build a new timeline from a config.
    pub fn new(show: SkyShowConfig) -> Self {
        let total_duration_ticks = show
            .slides
            .iter()
            .map(|s| s.duration_ticks)
            .sum::<u64>()
            .max(1);
        Self {
            show,
            total_duration_ticks,
        }
    }

    /// Convenience constructor mirroring your 1..8 image slideshow.
    pub fn default_eight() -> Self {
        Self::new(SkyShowConfig::default_eight())
    }

    /// Returns the slide that should be visible at a given tick.
    /// Ticks are interpreted modulo the total show length.
    pub fn slide_at_tick(&self, tick: u64) -> Option<&SkySlideRef> {
        let mut t = tick % self.total_duration_ticks;
        for slide in &self.show.slides {
            if t < slide.duration_ticks {
                return Some(slide);
            }
            t -= slide.duration_ticks;
        }
        // Should not happen because of the max(1) above, but just in case:
        self.show.slides.last()
    }

    /// Expose total duration for callers.
    pub fn total_duration_ticks(&self) -> u64 {
        self.total_duration_ticks
    }
}

/// A tiny "ray" placeholder, matching the mental model from RayTraceEngine.
/// For now this is just a stub; you can grow it as you port more sky math.
#[derive(Debug, Clone)]
pub struct SkyRay {
    pub origin: [f32; 3],
    pub direction: [f32; 3],
    pub color: [f32; 3],
}

impl SkyRay {
    pub fn new(origin: [f32; 3], direction: [f32; 3], color: [f32; 3]) -> Self {
        Self {
            origin,
            direction,
            color,
        }
    }
}
