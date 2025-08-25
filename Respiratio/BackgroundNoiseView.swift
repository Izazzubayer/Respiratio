import SwiftUI

/// Top-level list of background noises.
struct BackgroundNoiseView: View {
    // Plug in your catalog/source of noises
    private let noises: [BackgroundNoise] = NoiseCatalog.all

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background to match the app theme
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                List {
                    ForEach(noises, id: \.self) { noise in
                        NavigationLink(value: noise) {
                            NoiseRow(noise: noise)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden) // Remove white background
                .background(Color.clear) // Ensure transparent background
            }
            .navigationTitle("Background Noise")
            // Push the full player page
            .navigationDestination(for: BackgroundNoise.self) { noise in
                NoiseSessionView(noise: noise)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
        }
    }
}

/// A single row following consistent HIG design pattern.
private struct NoiseRow: View {
    let noise: BackgroundNoise

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(noise.title)
                .font(.headline) // HIG standard for section titles
                .foregroundStyle(.primary)
                .lineLimit(1)

            if !noise.summary.isEmpty {
                Text(noise.summary)
                    .font(.body) // HIG standard for main content
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Tag moved below description with proper HIG spacing
            if !noise.tags.isEmpty, let firstTag = noise.tags.first {
                Text(firstTag.capitalized)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(noise.tint)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(noise.tint.opacity(0.12)))
            }
        }
        .padding(.vertical, 12) // Increased padding for better spacing
        .frame(minHeight: 72, alignment: .leading) // Increased height for more text space
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
