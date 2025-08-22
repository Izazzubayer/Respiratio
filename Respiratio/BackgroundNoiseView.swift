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

/// A single row with icon + title + description + tags (Apple-style).
private struct NoiseRow: View {
    let noise: BackgroundNoise

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: noise.icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(noise.tint)

            // Texts
            VStack(alignment: .leading, spacing: 8) {
                Text(noise.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                if !noise.summary.isEmpty {
                    Text(noise.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !noise.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(noise.tags, id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(Capsule().fill(noise.tint.opacity(0.12)))
                                .foregroundStyle(noise.tint)
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(noise.title). \(noise.summary)")
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
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro")
}

#Preview("Background Noise View - iPhone Dark") {
    BackgroundNoiseView()
        .preferredColorScheme(.dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro - Dark Mode")
}

#Preview("Background Noise View - iPad") {
    BackgroundNoiseView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
        .previewDisplayName("iPad Pro")
}

#Preview("Noise Row Components") {
    List {
        ForEach(NoiseCatalog.all.prefix(3), id: \.self) { noise in
            NoiseRow(noise: noise)
                .padding(.vertical, 6)
        }
    }
    .listStyle(.insetGrouped)
    .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
    .previewDisplayName("Noise Row Components")
}
