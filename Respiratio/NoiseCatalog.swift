import Foundation

/// Single source of truth for the four noises you wanted.
enum NoiseCatalog {
    static let all: [BackgroundNoise] = [
        BackgroundNoise(
            title: "White Noise",
            summary: "Broad‑spectrum sound that masks distractions and helps with focus or sleep.",
            tags: ["Focus", "Sleep", "Masking"],
            fileName: "white-noise"
        ),
        BackgroundNoise(
            title: "Brown Noise",
            summary: "Low‑frequency–weighted noise; deeper and smoother for relaxation and calm.",
            tags: ["Relaxation", "Calm", "Sleep"],
            fileName: "brown-noise"
        ),
        BackgroundNoise(
            title: "Theta Wave",
            summary: "Slow rhythmic tones associated with meditative and drowsy states.",
            tags: ["Relaxation", "Meditation"],
            fileName: "theta-wave"
        ),
        BackgroundNoise(
            title: "Beta Wave",
            summary: "Faster rhythmic tones associated with alertness and concentration.",
            tags: ["Focus", "Productivity"],
            fileName: "beta-wave"
        )
    ]
}
