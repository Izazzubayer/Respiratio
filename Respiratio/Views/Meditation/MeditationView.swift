//
//  MeditationView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-20.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

// MARK: - Data
// Note: MeditationPreset is now defined in Domain/Entities/MeditationSession.swift
// This file uses the new domain entity for consistency

// Migration helper to convert old preset format to new domain format
private func createDomainPreset(
    title: String,
    description: String,
    minutes: Int,
    symbol: String,
    audioFileName: String?,
    hasAudio: Bool,
    tags: [String]
) -> MeditationPreset {
    // Map tags to appropriate category
    let category: MeditationCategory
    if tags.contains("Focus") || tags.contains("Study") || tags.contains("Work") {
        category = .focus
    } else if tags.contains("Stress Relief") || tags.contains("Anxiety Reduction") {
        category = .stress
    } else if tags.contains("Deep Relaxation") || tags.contains("Wind-Down") {
        category = .relaxation
    } else if tags.contains("Reset") || tags.contains("Refresh") {
        category = .mindfulness
    } else {
        category = .mindfulness
    }
    
    // Map duration to difficulty
    let difficulty: DifficultyLevel
    if minutes <= 5 {
        difficulty = .beginner
    } else if minutes <= 15 {
        difficulty = .intermediate
    } else {
        difficulty = .advanced
    }
    
    return MeditationPreset(
        title: title,
        description: description,
        duration: TimeInterval(minutes * 60), // Convert minutes to seconds
        category: category,
        difficulty: difficulty,
        symbol: symbol,
        audioFileName: audioFileName,
        hasAudio: hasAudio,
        tags: tags
    )
}

private let quickMeditations: [MeditationPreset] = [
    createDomainPreset(
        title: "2-Minute Quick Reset",
        description: "Perfect for a quick mental refresh during busy days. Ideal for office breaks, before meetings, or when you need to reset your mind.",
        minutes: 2,
        symbol: "waveform",
        audioFileName: "2min",
        hasAudio: true,
        tags: ["Reset", "Meeting", "Refresh"]
    ),
    createDomainPreset(
        title: "5-Minute Focus Boost",
        description: "Enhance concentration and mental clarity. Great for students before studying, professionals before important tasks, or to sharpen their focus.",
        minutes: 5,
        symbol: "waveform",
        audioFileName: "5min",
        hasAudio: true,
        tags: ["Focus", "Study", "Work"]
    ),
    createDomainPreset(
        title: "10-Minute Guided Journey",
        description: "A guided meditation experience with audio narration. Perfect for beginners who want direction, or anyone seeking a deeper, more immersive meditation session.",
        minutes: 10,
        symbol: "waveform",
        audioFileName: "10-min",
        hasAudio: true,
        tags: ["Guided", "Calm", "Relaxation"]
    ),
    createDomainPreset(
        title: "15-Minute Deep Calm",
        description: "Achieve deeper relaxation and inner peace. Ideal for evening wind-down, stress relief, or when you need extended time to quiet your mind and find tranquility.",
        minutes: 15,
        symbol: "waveform",
        audioFileName: "15min",
        hasAudio: true,
        tags: ["Deep Relaxation", "Wind-Down"]
    ),
    createDomainPreset(
        title: "20-Minute Stress Relief",
        description: "Comprehensive stress reduction and emotional balance. Perfect for high-stress days, anxiety relief, or when you need substantial time to process emotions and find equilibrium.",
        minutes: 20,
        symbol: "waveform",
        audioFileName: "20min",
        hasAudio: true,
        tags: ["Stress Relief", "Anxiety Reduction"]
    ),
    // Note: 30-minute meditation commented out as it would be advanced level
]

// MARK: - View

struct MeditationView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MEDITATION")
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                        
                        Text("Choose how you'd like to meditate today")
                            .font(.custom("AnekGujarati-Regular", size: 18))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    
                    // Scrollable Meditation cards
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(Array(quickMeditations.enumerated()), id: \.element.id) { index, preset in
                        NavigationLink {
                            MeditationSessionView(preset: preset)
                        } label: {
                            MeditationCard(preset: preset, colorIndex: index)
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

private struct MeditationCard: View {
    let preset: MeditationPreset
    let colorIndex: Int
    
    // Map meditation to vector illustration (sequence: vector-4, 3, 2, 1, 0...)
    private var illustrationName: String {
        switch colorIndex {
        case 0: return "vector-4" // 2-Minute Quick Reset
        case 1: return "vector-3" // 5-Minute Focus Boost
        case 2: return "vector-2" // 10-Minute Guided Journey
        case 3: return "vector-1" // 15-Minute Deep Calm
        case 4: return "vector-0" // 20-Minute Stress Relief
        default: return "vector-1" // fallback
        }
    }
    
    // Color scheme for each card
    private var cardColors: [Color] {
        [
            Color(red: 0.56, green: 0.59, blue: 0.99), // Blue
            Color(red: 0.98, green: 0.43, blue: 0.35), // Orange
            Color(red: 0.25, green: 0.25, blue: 0.31), // Dark gray
            Color(red: 0.42, green: 0.70, blue: 0.56), // Green
            Color(red: 0.95, green: 0.74, blue: 0.43), // Yellow
            Color(red: 0.56, green: 0.59, blue: 0.99)  // Blue (repeat)
        ]
    }
    
    private var tagColors: [Color] {
        [
            Color(red: 0.45, green: 0.49, blue: 0.94), // Blue tags
            Color(red: 0.84, green: 0.36, blue: 0.28), // Orange tags
            Color(red: 0.19, green: 0.19, blue: 0.19), // Dark tags
            Color(red: 0.34, green: 0.56, blue: 0.44), // Green tags
            Color(red: 0.83, green: 0.63, blue: 0.31), // Yellow tags
            Color(red: 0.45, green: 0.49, blue: 0.94)  // Blue tags (repeat)
        ]
    }
    
    // Convert duration to minutes for display
    private var durationInMinutes: Int {
        Int(preset.duration / 60)
    }
    
    // Create tags based on category and difficulty
    private var displayTags: [String] {
        var tags: [String] = []
        
        // Add category tag
        tags.append(preset.category.rawValue.capitalized)
        
        // Add difficulty tag
        tags.append(preset.difficulty.rawValue.capitalized)
        
        // Add duration tag
        tags.append("\(durationInMinutes) min")
        
        return tags
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColors[colorIndex % cardColors.count])
            
        VStack(spacing: 16) {
            // Top row: Content and illustration side by side
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Vector illustration side
                Image(illustrationName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 136, height: 136)
            }
            
            // Bottom row: Tags spanning full width below both content and illustration
            if !displayTags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(displayTags.prefix(3)), id: \.self) { tag in
                        Text(tag)
                            .font(.custom("AnekGujarati-Medium", size: 12))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            // .frame(maxWidth: 100)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.3))
                            )
                    }
                    Spacer()
                }
            }
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(preset.title). \(preset.description)")
        .accessibilityHint("Tap to start \(durationInMinutes) minute meditation session")
    }
}



// SectionHeader is now available from DesignSystem.Layout

// MARK: - Preview

#Preview("Meditation View - iPhone") {
    MeditationView()
}

#Preview("Meditation View - iPhone Dark") {
    MeditationView()
        .preferredColorScheme(.dark)
}

#Preview("Meditation View - iPad") {
    MeditationView()
}

#Preview("Meditation Card Component") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            MeditationCard(preset: quickMeditations[0], colorIndex: 0)
            MeditationCard(preset: quickMeditations[2], colorIndex: 2)
            MeditationCard(preset: quickMeditations[4], colorIndex: 4)
        }
        .padding(.horizontal, 24)
    }
}

#Preview("All Meditation Cards") {
    ZStack {
        Color(red: 0.21, green: 0.35, blue: 0.97)
            .ignoresSafeArea()
        
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(Array(quickMeditations.enumerated()), id: \.element.id) { index, preset in
                    MeditationCard(preset: preset, colorIndex: index)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
        }
    }
}


