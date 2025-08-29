//
//  BreathingExercise.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//
import SwiftUI

struct BreathPhase: Identifiable {
    enum Kind: String { case inhale, hold, exhale }
    let id = UUID()
    let kind: Kind
    let seconds: Int
}

struct BreathingExercise: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let cycle: [BreathPhase]
    let description: String
}

extension BreathingExercise {
    static let box = BreathingExercise(
        title: "Box Breathing",
        subtitle: "4s in • 4s hold • 4s out • 4s hold",
        symbol: "square.dashed.inset.filled",
        tint: .blue,
        cycle: [
            .init(kind: .inhale, seconds: 4),
            .init(kind: .hold,   seconds: 4),
            .init(kind: .exhale, seconds: 4),
            .init(kind: .hold,   seconds: 4)
        ],
        description: "Inhale, hold, exhale, and hold again for equal counts to calm the mind and sharpen focus."
    )

    static let fourSevenEight = BreathingExercise(
        title: "4-7-8 Breathing",
        subtitle: "4s in • 7s hold • 8s out",
        symbol: "triangle.fill",
        tint: .indigo,
        cycle: [
            .init(kind: .inhale, seconds: 4),
            .init(kind: .hold,   seconds: 7),
            .init(kind: .exhale, seconds: 8)
        ],
        description: "Promotes deep relaxation and better sleep. Inhale for 4, hold for 7, exhale for 8. Helps reduce anxiety and prepare the body for rest."
    )

    static let equal = BreathingExercise(
        title: "Equal Breathing",
        subtitle: "5s in • 5s out",
        symbol: "arrow.left.and.right.circle.fill",
        tint: .green,
        cycle: [
            .init(kind: .inhale, seconds: 5),
            .init(kind: .exhale, seconds: 5)
        ],
        description: "Also known as Sama Vritti. Inhale and exhale for equal counts to create balance, reduce stress, and improve focus."
    )

    static let resonant = BreathingExercise(
        title: "Resonant Breathing",
        subtitle: "6s in • 6s out",
        symbol: "waveform.path.ecg.rectangle",
        tint: .orange,
        cycle: [
            .init(kind: .inhale, seconds: 6),
            .init(kind: .exhale, seconds: 6)
        ],
        description: "A slow 6-6 rhythm that optimizes heart-rate variability. Helps the body find its natural calm and restore balance."
    )

    static let triangle = BreathingExercise(
        title: "Triangle Breathing",
        subtitle: "4s in • 4s hold • 4s out",
        symbol: "triangle.lefthalf.filled",
        tint: .purple,
        cycle: [
            .init(kind: .inhale, seconds: 4),
            .init(kind: .hold,   seconds: 4),
            .init(kind: .exhale, seconds: 4)
        ],
        description: "A simple three-step rhythm: inhale, hold, exhale. Builds endurance, strengthens focus, and reduces nervous tension."
    )

    static let all: [BreathingExercise] = [
        .box, .fourSevenEight, .equal, .resonant, .triangle
    ]
}
