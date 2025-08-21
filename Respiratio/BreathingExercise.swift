//
//  BreathingExercise.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//
import SwiftUI

struct BreathPhase: Identifiable, Equatable {
    enum Kind: String { case inhale, hold, exhale }
    let id = UUID()
    let kind: Kind
    let seconds: Int
}

/// Techniques. Identifiable only (Color & arrays aren’t Hashable).
struct BreathingExercise: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color
    let cycle: [BreathPhase]

    // ✅ Box = Inhale → Hold → Exhale (repeats)
    static let box = BreathingExercise(
        title: "Box Breathing",
        subtitle: "4s in • 4s hold • 4s out",
        symbol: "square.dashed.inset.filled",
        tint: .blue,
        cycle: [
            .init(kind: .inhale, seconds: 4),
            .init(kind: .hold,   seconds: 4),
            .init(kind: .exhale, seconds: 4)
        ]
    )

    static let equal = BreathingExercise(
        title: "Equal Breathing",
        subtitle: "5s in • 5s out",
        symbol: "arrow.left.and.right.circle.fill",
        tint: .mint,
        cycle: [.init(kind: .inhale, seconds: 5),
                .init(kind: .exhale, seconds: 5)]
    )

    static let fourSevenEight = BreathingExercise(
        title: "4‑7‑8",
        subtitle: "4s in • 7s hold • 8s out",
        symbol: "triangle.fill",
        tint: .purple,
        cycle: [.init(kind: .inhale, seconds: 4),
                .init(kind: .hold,   seconds: 7),
                .init(kind: .exhale, seconds: 8)]
    )

    static let resonant = BreathingExercise(
        title: "Resonant (Coherent)",
        subtitle: "4s in • 6s out",
        symbol: "waveform.path.ecg.rectangle",
        tint: .orange,
        cycle: [.init(kind: .inhale, seconds: 4),
                .init(kind: .exhale, seconds: 6)]
    )

    static let triangle = BreathingExercise(
        title: "Triangle",
        subtitle: "4s in • 4s hold • 4s out",
        symbol: "triangle.circle.fill",
        tint: .green,
        cycle: [.init(kind: .inhale, seconds: 4),
                .init(kind: .hold,   seconds: 4),
                .init(kind: .exhale, seconds: 4)]
    )

    static let all: [BreathingExercise] = [.box, .equal, .fourSevenEight, .resonant, .triangle]
}
