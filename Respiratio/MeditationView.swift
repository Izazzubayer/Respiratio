//
//  MeditationView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-20.
//

import SwiftUI

// MARK: - Data

struct MeditationPreset: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let minutes: Int
    let symbol: String
    let audioFileName: String? // Optional audio file for guided meditation
    let hasAudio: Bool
    let tags: [String] // Use case tags for each meditation
}

private let quickMeditations: [MeditationPreset] = [
    .init(
        title: "2-Minute Quick Reset",
        description: "Perfect for a quick mental refresh during busy days. Ideal for office breaks, before meetings, or when you need to reset your mind quickly.",
        minutes: 2,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Quick Reset", "Pre-Meeting", "Mental Refresh"]
    ),
    .init(
        title: "5-Minute Focus Boost",
        description: "Enhance concentration and mental clarity. Great for students before studying, professionals before important tasks, or anyone needing to sharpen their focus.",
        minutes: 5,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Focus", "Study Prep", "Work Focus"]
    ),
    .init(
        title: "10-Minute Guided Journey",
        description: "A guided meditation experience with audio narration. Perfect for beginners who want direction, or anyone seeking a deeper, more immersive meditation session.",
        minutes: 10,
        symbol: "waveform",
        audioFileName: "10-min",
        hasAudio: true,
        tags: ["Guided", "Calm", "Relaxation"]
    ),
    .init(
        title: "15-Minute Deep Calm",
        description: "Achieve deeper relaxation and inner peace. Ideal for evening wind-down, stress relief, or when you need extended time to quiet your mind and find tranquility.",
        minutes: 15,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Deep Relaxation", "Evening Wind-Down"]
    ),
    .init(
        title: "20-Minute Stress Relief",
        description: "Comprehensive stress reduction and emotional balance. Perfect for high-stress days, anxiety relief, or when you need substantial time to process emotions and find equilibrium.",
        minutes: 20,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Stress Relief", "Anxiety Reduction"]
    ),
    .init(
        title: "30-Minute Inner Peace",
        description: "Transformative meditation for profound inner transformation. Designed for experienced practitioners seeking deep spiritual connection, self-discovery, and lasting inner peace.",
        minutes: 30,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Spiritual Growth", "Self-Discovery"]
    ),
]

// MARK: - View

struct MeditationView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(quickMeditations) { preset in
                        // Use direct destination variant to avoid any routing mismatch
                        NavigationLink {
                            MeditationSessionView(preset: preset)
                        } label: {
                            MeditationRow(preset: preset)
                        }
                        // IMPORTANT: Do NOT add any gestures/haptic modifiers to this row
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Meditation")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Components

private struct MeditationRow: View {
    let preset: MeditationPreset

    var body: some View {
        HStack(spacing: 16) {
            // Content following HIG typography hierarchy - icons removed for more text space
            VStack(alignment: .leading, spacing: 8) { // Increased from 4 to 8 for better HIG spacing
                HStack(spacing: 8) {
                    Text(preset.title)
                        .font(.headline) // HIG standard for section titles
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if preset.hasAudio {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .accessibilityLabel("Guided meditation with audio")
                    }
                }

                // Description text
                Text(preset.description)
                    .font(.body) // HIG standard for main content
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Tags showing use cases
                if !preset.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(preset.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption.weight(.medium))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Capsule().fill(.blue.opacity(0.12)))
                                    .foregroundStyle(.blue)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                

            }

            Spacer()
        }
        .padding(.vertical, 8) // 8pt grid system
        .frame(minHeight: 80) // Increased height for description and tags
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.title). \(preset.description)")
        .accessibilityHint("Tap to start meditation session")
    }
}



private struct SectionHeader: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .textCase(nil)
    }
}

// MARK: - Preview

#Preview("Meditation View - iPhone") {
    MeditationView()
}

#Preview("Meditation View - iPhone Dark") {
    MeditationView()
        .preferredColorScheme(.dark)
}

#Preview("Meditation View - iPad") {
    MeditationView()
}

#Preview("Meditation Row Component") {
    NavigationStack {
        List {
            MeditationRow(preset: quickMeditations[0])
            MeditationRow(preset: quickMeditations[2])
            MeditationRow(preset: quickMeditations[4])
        }
        .listStyle(.insetGrouped)
    }
}



#Preview("Meditation Row with Description and Tags") {
    NavigationStack {
        List {
            MeditationRow(preset: quickMeditations[0]) // 2-Minute
            MeditationRow(preset: quickMeditations[2]) // 10-Minute Guided
            MeditationRow(preset: quickMeditations[4]) // 20-Minute
        }
        .listStyle(.insetGrouped)
    }
}
