import SwiftUI

struct BreathingView: View {
    // Data source (defined in BreathingExercise.swift)
    private let items = BreathingExercise.all

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        // Page title
                        Text("Breathing")
                            .font(.system(size: 44, weight: .bold))
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Cards
                        VStack(spacing: 14) {
                            ForEach(items) { exercise in
                                NavigationLink {
                                    BreathingSessionView(exercise: exercise, totalSeconds: 120)
                                } label: {
                                    BreathingRowCard(exercise: exercise)
                                }
                                .buttonStyle(.plain)
                                .simultaneousGesture(TapGesture().onEnded {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

private struct BreathingRowCard: View {
    let exercise: BreathingExercise

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Leading icon
            Image(systemName: exercise.symbol)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(exercise.tint.opacity(0.28), in: .circle)

            // Text block — full width (no time pill, no chevron)
            VStack(alignment: .leading, spacing: 8) {
                Text(exercise.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(exercise.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // allow multi‑line
                    .multilineTextAlignment(.leading)

                Divider().opacity(0.2)

                Text(exercise.subtitle)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0) // no trailing accessories
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .contentShape(Rectangle()) // whole card tappable
    }
}

// MARK: - Preview

#Preview("Breathing View - iPhone") {
    BreathingView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro")
}

#Preview("Breathing View - iPhone Dark") {
    BreathingView()
        .preferredColorScheme(.dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro - Dark Mode")
}

#Preview("Breathing View - iPad") {
    BreathingView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
        .previewDisplayName("iPad Pro")
}

#Preview("Breathing Card Components") {
    ScrollView {
        VStack(spacing: 14) {
            ForEach(BreathingExercise.all) { exercise in
                BreathingRowCard(exercise: exercise)
            }
        }
        .padding(20)
    }
    .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
    .previewDisplayName("Breathing Card Components")
}
