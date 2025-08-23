import SwiftUI

struct BreathingView: View {
    // Data source (defined in BreathingExercise.swift)
    private let items = BreathingExercise.all

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { exercise in
                        NavigationLink {
                            BreathingSessionView(exercise: exercise, totalSeconds: 120)
                        } label: {
                            BreathingRow(exercise: exercise)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

private struct BreathingRow: View {
    let exercise: BreathingExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(exercise.title)
                .font(.headline) // HIG standard for section titles
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(exercise.description)
                .font(.body) // HIG standard for main content
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)

            Text(exercise.subtitle)
                .font(.caption) // HIG standard for secondary text
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 12) // Increased padding for better spacing
        .frame(minHeight: 72, alignment: .leading) // Increased height for more text space
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.title). \(exercise.description)")
        .accessibilityHint("Tap to start breathing exercise")
    }
}

// MARK: - Preview

#Preview("Breathing View - iPhone") {
    BreathingView()
}

#Preview("Breathing View - iPhone Dark") {
    BreathingView()
        .preferredColorScheme(.dark)
}

#Preview("Breathing View - iPad") {
    BreathingView()
}

#Preview("Breathing Card Components") {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(BreathingExercise.all) { exercise in
                                            BreathingRow(exercise: exercise)
            }
        }
        .padding(20)
    }
}
