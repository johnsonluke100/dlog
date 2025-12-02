//! SkyLighting logic for the Ω universe.

use spec::{SkyShowConfig, SkySlideRef};

/// Runtime representation of a looping sky timeline.
#[derive(Debug, Clone)]
pub struct SkyTimeline {
    show: SkyShowConfig,
    total_duration_ticks: u64,
}

impl SkyTimeline {
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

    pub fn default_eight() -> Self {
        Self::new(SkyShowConfig::default_eight())
    }

    pub fn show(&self) -> &SkyShowConfig {
        &self.show
    }

    pub fn slide_at_tick(&self, tick: u64) -> Option<&SkySlideRef> {
        let mut t = tick % self.total_duration_ticks;
        for slide in &self.show.slides {
            if t < slide.duration_ticks {
                return Some(slide);
            }
            t -= slide.duration_ticks;
        }
        self.show.slides.last()
    }

    pub fn total_duration_ticks(&self) -> u64 {
        self.total_duration_ticks
    }
}

/// A tiny "ray" placeholder, matching the mental model from RayTraceEngine.
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
