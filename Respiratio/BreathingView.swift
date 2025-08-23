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
        HStack(spacing: 16) {
            // Icon with consistent styling across tabs
            ZStack {
                Circle().fill(exercise.tint.opacity(0.15))
                Image(systemName: exercise.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(exercise.tint)
            }
            .frame(width: 44, height: 44) // HIG minimum tap target
            .accessibilityHidden(true)

            // Content following HIG typography hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.title)
                    .font(.headline) // HIG standard for section titles
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(exercise.subtitle)
                    .font(.body) // HIG standard for main content
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Duration indicator - consistent with other tabs
            Text("2 min")
                .font(.caption.weight(.medium))
                .foregroundStyle(exercise.tint)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Capsule().fill(exercise.tint.opacity(0.12)))
        }
        .padding(.vertical, 8) // 8pt grid system
        .frame(minHeight: 52) // HIG preferred list row height
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.title). \(exercise.subtitle)")
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
