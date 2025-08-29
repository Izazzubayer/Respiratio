import SwiftUI

// MARK: - Data

struct NoisePreset: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let summary: String
    let tags: [String]
    let fileName: String
    let colorIndex: Int
    let noise: BackgroundNoise
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NoisePreset, rhs: NoisePreset) -> Bool {
        lhs.id == rhs.id
    }
}

private let noisePresets: [NoisePreset] = [
    .init(
        title: "White Noise",
        summary: "Broad‑spectrum sound that masks distractions and helps with focus or sleep.",
        tags: ["Focus", "Sleep", "Masking"],
        fileName: "white-noise",
        colorIndex: 0,
        noise: NoiseCatalog.all[0]
    ),
    .init(
        title: "Brown Noise",
        summary: "Low‑frequency–weighted noise; deeper and smoother for relaxation and calm.",
        tags: ["Relaxation", "Calm", "Sleep"],
        fileName: "brown-noise",
        colorIndex: 1,
        noise: NoiseCatalog.all[1]
    ),
    .init(
        title: "Theta Wave",
        summary: "Slow rhythmic tones associated with meditative and drowsy states.",
        tags: ["Meditation", "Deep Sleep"],
        fileName: "theta-wave",
        colorIndex: 2,
        noise: NoiseCatalog.all[2]
    ),
    .init(
        title: "Beta Wave",
        summary: "Faster rhythmic tones associated with alertness and concentration.",
        tags: ["Energy", "Concentration"],
        fileName: "beta-wave",
        colorIndex: 3,
        noise: NoiseCatalog.all[3]
    )
]

// MARK: - View

struct BackgroundNoiseView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Enhanced Header section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BACKGROUND NOISE")
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                        
                        Text("Choose your ambient soundscape")
                            .font(.custom("AnekGujarati-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Scrollable Noise cards
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(noisePresets) { preset in
                                NavigationLink {
                                    NoiseSessionView(noise: preset.noise)
                                } label: {
                                    NoiseCard(preset: preset)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .tabBar)
        }
    }
}

// MARK: - Components

private struct NoiseCard: View {
    let preset: NoisePreset
    
    // Color scheme for each card
    private var cardGradient: LinearGradient {
        switch preset.title {
        case "White Noise":
            return LinearGradient(
                colors: [Color(red: 0.56, green: 0.59, blue: 0.99), Color(red: 0.56, green: 0.59, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Brown Noise":
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.43, blue: 0.35), Color(red: 0.98, green: 0.43, blue: 0.35)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Theta Wave":
            return LinearGradient(
                colors: [Color(red: 0.25, green: 0.25, blue: 0.31), Color(red: 0.25, green: 0.25, blue: 0.31)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Beta Wave":
            return LinearGradient(
                colors: [Color(red: 0.42, green: 0.70, blue: 0.56), Color(red: 0.42, green: 0.70, blue: 0.56)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(red: 0.56, green: 0.59, blue: 0.99), Color(red: 0.56, green: 0.59, blue: 0.99)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Enhanced SF Symbol for each noise type
    private var iconName: String {
        switch preset.title {
        case "White Noise": return "waveform.path.ecg"
        case "Brown Noise": return "drop.fill"
        case "Theta Wave": return "circle.grid.cross.fill"
        case "Beta Wave": return "bolt.circle.fill"
        default: return "music.note"
        }
    }
    
    // Tag colors for each noise type - semi-dark for better visibility
    private func tagColor(for title: String) -> Color {
        switch title {
        case "White Noise": return Color.black.opacity(0.3) // Semi-dark for blue background
        case "Brown Noise": return Color.black.opacity(0.3) // Semi-dark for orange background
        case "Theta Wave": return Color.black.opacity(0.3) // Semi-dark for dark background
        case "Beta Wave": return Color.black.opacity(0.3) // Semi-dark for green background
        default: return Color.black.opacity(0.3)
        }
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(cardGradient)
            
            HStack(spacing: 16) {
                // Content side
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preset.title)
                            .font(.custom("AnekGujarati-Bold", size: 20))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(preset.summary)
                            .font(.custom("AnekGujarati-Regular", size: 14))
                            .lineSpacing(1)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                                        // Tags
                    if !preset.tags.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(preset.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                                Text(tag)
                                    .font(.custom("AnekGujarati-Medium", size: 12))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(tagColor(for: preset.title))
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Icon side
                Image(systemName: iconName)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.title). \(preset.summary)")
        .accessibilityHint("Tap to play background noise")
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

#Preview("Noise Card Component") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            NoiseCard(preset: noisePresets[0])
            NoiseCard(preset: noisePresets[1])
        }
        .padding(.horizontal, 24)
    }
}

#Preview("All Noise Cards") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(noisePresets) { preset in
                    NoiseCard(preset: preset)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}
