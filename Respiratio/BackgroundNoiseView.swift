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
        tags: ["Relaxation", "Meditation"],
        fileName: "theta-wave",
        colorIndex: 2,
        noise: NoiseCatalog.all[2]
    ),
    .init(
        title: "Beta Wave",
        summary: "Faster rhythmic tones associated with alertness and concentration.",
        tags: ["Focus", "Productivity"],
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
                    // Fixed Header section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BACKGROUND NOISE")
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                        
                        Text("Choose your ambient soundscape")
                            .font(.custom("AnekGujarati-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.6))
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
    private var cardColors: [Color] {
        [
            Color(red: 0.56, green: 0.59, blue: 0.99), // Blue
            Color(red: 0.98, green: 0.43, blue: 0.35), // Orange
            Color(red: 0.25, green: 0.25, blue: 0.31), // Dark gray
            Color(red: 0.42, green: 0.70, blue: 0.56), // Green
        ]
    }
    
    private var tagColors: [Color] {
        [
            Color(red: 0.45, green: 0.49, blue: 0.94), // Blue tags
            Color(red: 0.84, green: 0.36, blue: 0.28), // Orange tags
            Color(red: 0.19, green: 0.19, blue: 0.19), // Dark tags
            Color(red: 0.34, green: 0.56, blue: 0.44), // Green tags
        ]
    }
    
    // SF Symbol for each noise type
    private var iconName: String {
        switch preset.title {
        case "White Noise": return "waveform"
        case "Brown Noise": return "drop.fill"
        case "Theta Wave": return "circle.grid.cross"
        case "Beta Wave": return "bolt.circle.fill"
        default: return "music.note"
        }
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColors[preset.colorIndex % cardColors.count])
            
            HStack(spacing: 16) {
                // Content side
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.title)
                            .font(.custom("AnekGujarati-Bold", size: 22))
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
                                    .font(.custom("AnekGujarati-Medium", size: 10))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(
                                        Capsule()
                                            .fill(tagColors[preset.colorIndex % tagColors.count])
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
