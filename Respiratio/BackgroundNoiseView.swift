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
                    // Enhanced Header section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("BACKGROUND NOISE")
                            .font(.custom("Amagro-Bold", size: 28))
                            .foregroundColor(.white)
                        
                        Text("Choose your ambient soundscape")
                            .font(.custom("AnekGujarati-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    
                    // Scrollable Noise cards
                    ScrollView {
                        LazyVStack(spacing: 20) {
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
    
    // Enhanced color scheme for each card
    private var cardGradient: LinearGradient {
        switch preset.title {
        case "White Noise":
            return LinearGradient(
                colors: [Color(hex: "#4A90E2"), Color(hex: "#357ABD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Brown Noise":
            return LinearGradient(
                colors: [Color(hex: "#E67E22"), Color(hex: "#D35400")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Theta Wave":
            return LinearGradient(
                colors: [Color(hex: "#9B59B6"), Color(hex: "#8E44AD")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case "Beta Wave":
            return LinearGradient(
                colors: [Color(hex: "#F1C40F"), Color(hex: "#F39C12")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [Color(hex: "#4A90E2"), Color(hex: "#357ABD")],
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

    var body: some View {
        ZStack {
            // Enhanced card background with gradient and shadow
            RoundedRectangle(cornerRadius: 24)
                .fill(cardGradient)
                .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            
            HStack(spacing: 20) {
                // Content side
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(preset.title)
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(preset.summary)
                            .font(.custom("AnekGujarati-Regular", size: 15))
                            .lineSpacing(2)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Enhanced tags
                    if !preset.tags.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(Array(preset.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                                Text(tag)
                                    .font(.custom("AnekGujarati-Medium", size: 11))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 14)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.25))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                                            )
                                    )
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Enhanced icon side
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 88, height: 88)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
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
