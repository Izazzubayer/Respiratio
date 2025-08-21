//
//  BackgroundNoise.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import Foundation

struct BackgroundNoise: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let tags: [String]   // multiple tags
    let filename: String // .wav file in bundle
}

let backgroundNoises: [BackgroundNoise] = [
    BackgroundNoise(
        name: "White Noise",
        description: "White noise encompasses all audible frequencies at equal intensity, creating a consistent, static sound. Huberman suggests it can help mask distracting sounds.",
        tags: ["Focus", "Study", "Sleep"],
        filename: "WhiteNoise"
    ),
    BackgroundNoise(
        name: "Brown Noise",
        description: "Brown noise emphasizes lower frequencies, producing a deeper, more soothing sound. Useful for calming and less intrusive background sound.",
        tags: ["Relaxation", "Calm", "Sleep"],
        filename: "BrownNoise"
    ),
    BackgroundNoise(
        name: "40 Hz Binaural Beats",
        description: "Two slightly different frequencies create a third tone perceived by the brain. Can enhance focus and cognitive function. Use short sessions.",
        tags: ["Focus", "Cognition", "Short Session"],
        filename: "Binaural40Hz"
    )
]
