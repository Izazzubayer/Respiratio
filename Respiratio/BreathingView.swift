import SwiftUI

// MARK: - Data

struct BreathingPreset: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let subtitle: String
    let symbol: String
    let colorIndex: Int
    let exercise: BreathingExercise
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BreathingPreset, rhs: BreathingPreset) -> Bool {
        lhs.id == rhs.id
    }
}

private let breathingPresets: [BreathingPreset] = [
    .init(
        title: "Box Breathing",
        description: "Inhale, hold, exhale, and hold again. Repeat this for 2 minutes to calm the mind & sharpen focus.",
        subtitle: "4s in • 4s hold • 4s out • 4s hold",
        symbol: "square.dashed.inset.filled",
        colorIndex: 0,
        exercise: .box
    ),
    .init(
        title: "4-7-8 Breathing",
        description: "Promotes deep relaxation and better sleep. Inhale for 4, hold for 7, exhale for 8. Helps reduce anxiety and prepare the body for rest.",
        subtitle: "4s in • 7s hold • 8s out",
        symbol: "triangle.fill",
        colorIndex: 1,
        exercise: .fourSevenEight
    ),
    // .init(
    //     title: "Equal Breathing",
    //     description: "Also known as Sama Vritti. Inhale and exhale for equal counts to create balance, reduce stress, and improve focus.",
    //     subtitle: "5s in • 5s out",
    //     symbol: "arrow.left.and.right.circle.fill",
    //     colorIndex: 2,
    //     exercise: .equal
    // ),
    // .init(
    //     title: "Resonant Breathing",
    //     description: "A slow 6-6 rhythm that optimizes heart-rate variability. Helps the body find its natural calm and restore balance.",
    //     subtitle: "6s in • 6s out",
    //     symbol: "waveform.path.ecg.rectangle",
    //     colorIndex: 3,
    //     exercise: .resonant
    // ),
    // .init(
    //     title: "Triangle Breathing",
    //     description: "A simple three-step rhythm: inhale, hold, exhale. Builds endurance, strengthens focus, and reduces nervous tension.",
    //     subtitle: "4s in • 4s hold • 4s out",
    //     symbol: "triangle.lefthalf.filled",
    //     colorIndex: 4,
    //     exercise: .triangle
    // ),
]

// MARK: - View

struct BreathingView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BREATH WORK")
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                        
                        Text("Choose your breath-work")
                            .font(.custom("AnekGujarati-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Scrollable Breathing cards
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(breathingPresets) { preset in
                                NavigationLink {
                                    if preset.title == "Box Breathing" {
                                        BoxBreathingView()
                                    } else {
                                        BreathingSessionView(exercise: preset.exercise, totalSeconds: 120)
                                    }
                                } label: {
                                    BreathingCard(preset: preset)
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

private struct BreathingCard: View {
    let preset: BreathingPreset
    
    // Color scheme for each card
    private var cardColors: [Color] {
        [
            Color(red: 0.56, green: 0.59, blue: 0.99), // Blue
            Color(red: 0.98, green: 0.43, blue: 0.35), // Orange
            Color(red: 0.25, green: 0.25, blue: 0.31), // Dark gray
            Color(red: 0.42, green: 0.70, blue: 0.56), // Green
            Color(red: 0.95, green: 0.74, blue: 0.43), // Yellow
        ]
    }
    
    private var tagColors: [Color] {
        [
            Color(red: 0.45, green: 0.49, blue: 0.94), // Blue tags
            Color(red: 0.84, green: 0.36, blue: 0.28), // Orange tags
            Color(red: 0.19, green: 0.19, blue: 0.19), // Dark tags
            Color(red: 0.34, green: 0.56, blue: 0.44), // Green tags
            Color(red: 0.83, green: 0.63, blue: 0.31), // Yellow tags
        ]
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
                            .font(.custom("AnekGujarati-Bold", size: 20))
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(preset.description)
                            .font(.custom("AnekGujarati-Regular", size: 14))
                            .lineSpacing(1)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Subtitle as a tag
                    Text(preset.subtitle)
                        .font(.custom("AnekGujarati-Medium", size: 10))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            Capsule()
                                .fill(tagColors[preset.colorIndex % tagColors.count])
                        )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Icon side
                Image(systemName: preset.symbol)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.title). \(preset.description)")
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

#Preview("Breathing Card Component") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            BreathingCard(preset: breathingPresets[0])
            BreathingCard(preset: breathingPresets[1])
        }
        .padding(.horizontal, 24)
    }
}

#Preview("All Breathing Cards") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(breathingPresets) { preset in
                    BreathingCard(preset: preset)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}
