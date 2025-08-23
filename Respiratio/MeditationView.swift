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
    let minutes: Int
    let level: Level
    let symbol: String

    enum Level: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case pro = "Pro"

        var tint: Color {
            switch self {
            case .beginner: return .green
            case .intermediate: return .blue
            case .advanced: return .orange
            case .pro: return .purple
            }
        }
    }
}

private let quickMeditations: [MeditationPreset] = [
    .init(title: "2-Minute Meditation",  minutes: 2,  level: .beginner,     symbol: "leaf.fill"),
    .init(title: "5-Minute Meditation",  minutes: 5,  level: .beginner,     symbol: "leaf.fill"),
    .init(title: "10-Minute Meditation", minutes: 10, level: .intermediate, symbol: "leaf.fill"),
    .init(title: "15-Minute Meditation", minutes: 15, level: .intermediate, symbol: "leaf.fill"),
    .init(title: "20-Minute Meditation", minutes: 20, level: .advanced,     symbol: "leaf.fill"),
    .init(title: "30-Minute Meditation", minutes: 30, level: .pro,          symbol: "leaf.fill"),
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
                            MeditationSessionView(duration: preset.minutes * 60)
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
            // Icon with consistent styling across tabs
            ZStack {
                Circle().fill(preset.level.tint.opacity(0.15))
                Image(systemName: preset.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(preset.level.tint)
            }
            .frame(width: 44, height: 44) // HIG minimum tap target
            .accessibilityHidden(true)

            // Content following HIG typography hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.title)
                    .font(.headline) // HIG standard for section titles
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text("\(preset.minutes) min")
                    .font(.body) // HIG standard for main content
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Level badge - consistent with other tabs
            LevelBadge(level: preset.level)
                .allowsHitTesting(false)
        }
        .padding(.vertical, 8) // 8pt grid system
        .frame(minHeight: 52) // HIG preferred list row height
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.title). \(preset.minutes) minutes. \(preset.level.rawValue) level")
        .accessibilityHint("Tap to start meditation session")
    }
}

private struct LevelBadge: View {
    let level: MeditationPreset.Level

    var body: some View {
        Text(level.rawValue)
            .font(.caption.weight(.medium)) // Consistent with other badge styles
            .foregroundStyle(level.tint)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Capsule().fill(level.tint.opacity(0.12))) // Consistent opacity
            .accessibilityHidden(true) // Included in parent accessibility label
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

#Preview("Level Badge Components") {
    VStack(spacing: 20) {
        ForEach(MeditationPreset.Level.allCases, id: \.self) { level in
            LevelBadge(level: level)
        }
    }
    .padding()
}
