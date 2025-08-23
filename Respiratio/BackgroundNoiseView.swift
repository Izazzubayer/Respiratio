import SwiftUI

/// Top-level list of background noises.
struct BackgroundNoiseView: View {
    // Plug in your catalog/source of noises
    private let noises: [BackgroundNoise] = NoiseCatalog.all

    var body: some View {
        NavigationStack {
            List {
                ForEach(noises, id: \.self) { noise in
                    NavigationLink(value: noise) {
                        NoiseRow(noise: noise)
                            .padding(.vertical, 6)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Background Noise")
            // Push the full player page
            .navigationDestination(for: BackgroundNoise.self) { noise in
                NoiseSessionView(noise: noise)
            }
        }
    }
}

/// A single row following consistent HIG design pattern.
private struct NoiseRow: View {
    let noise: BackgroundNoise

    var body: some View {
        HStack(spacing: 16) {
            // Icon with consistent styling across tabs
            ZStack {
                Circle().fill(noise.tint.opacity(0.15))
                Image(systemName: noise.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(noise.tint)
            }
            .frame(width: 44, height: 44) // HIG minimum tap target
            .accessibilityHidden(true)

            // Content following HIG typography hierarchy
            VStack(alignment: .leading, spacing: 4) {
                Text(noise.title)
                    .font(.headline) // HIG standard for section titles
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !noise.summary.isEmpty {
                    Text(noise.summary)
                        .font(.body) // HIG standard for main content
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            // Status indicator - consistent with other tabs
            if !noise.tags.isEmpty, let firstTag = noise.tags.first {
                Text(firstTag.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(noise.tint)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(noise.tint.opacity(0.12)))
            }
        }
        .padding(.vertical, 8) // 8pt grid system
        .frame(minHeight: 52) // HIG preferred list row height
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(noise.title). \(noise.summary)")
        .accessibilityHint("Tap to play background noise")
    }
}

// MARK: - Icon / Tint helpers for the list
extension BackgroundNoise {
    /// SF Symbol to use for each noise in the list.
    var icon: String {
        switch title {
        case "White Noise": return "waveform"
        case "Brown Noise": return "drop.fill"
        case "Theta Wave": return "circle.grid.cross"
        case "Beta Wave":  return "bolt.circle.fill"
        default:            return "music.note"
        }
    }
    
    /// Subtle, consistent tint per noise.
    var tint: Color {
        switch title {
        case "White Noise": return .blue
        case "Brown Noise": return .brown
        case "Theta Wave":  return .purple
        case "Beta Wave":   return .yellow
        default:            return .blue
        }
    }
}

// MARK: - Preview

#Preview("Background Noise View - iPhone") {
    BackgroundNoiseView()
}

#Preview("Background Noise View - iPhone Dark") {
    BackgroundNoiseView()
        .preferredColorScheme(.dark)
}

#Preview("Background Noise View - iPad") {
    BackgroundNoiseView()
}

#Preview("Noise Row Components") {
    List {
        ForEach(NoiseCatalog.all.prefix(3), id: \.self) { noise in
            NoiseRow(noise: noise)
                .padding(.vertical, 6)
        }
    }
    .listStyle(.insetGrouped)
}
