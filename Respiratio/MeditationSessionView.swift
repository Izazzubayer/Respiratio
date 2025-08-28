//
//  MeditationSessionView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - ViewModel

final class MeditationSessionModel: ObservableObject {
    let total: Int
    @Published var remaining: Int
    @Published var isRunning: Bool = false
    @Published var finished: Bool = false

    private var cancellable: AnyCancellable?

    init(duration: Int) {
        self.total = max(1, duration)
        self.remaining = max(0, duration)
    }

    var progress: Double {
        guard total > 0 else { return 0 }
        return 1 - Double(remaining) / Double(total)
    }

    func start() {
        guard !isRunning && !finished else { return }
        isRunning = true
        tick()
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        cancellable?.cancel()
        cancellable = nil
    }

    func stop() { pause(); remaining = 0; finish() }

    private func tick() {
        guard isRunning else { return }
        remaining = max(remaining - 1, 0)
        if remaining == 0 { finish() }
    }

    private func finish() {
        pause()
        if !finished {
            finished = true
            #if os(iOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }
}

// MARK: - View

struct MeditationSessionView: View {
    let preset: MeditationPreset
    @StateObject private var model: MeditationSessionModel
    @StateObject private var audioEngine = MeditationAudioEngine.shared
    @StateObject private var streak = StreakStore()
    @Environment(\.dismiss) private var dismiss
    


    @State private var showCompletionSheet = false
    @State private var sessionDuration: TimeInterval = 0
    
    init(preset: MeditationPreset) {
        self.preset = preset
        _model = .init(wrappedValue: MeditationSessionModel(duration: preset.minutes * 60))
    }
    
    // Legacy initializer for compatibility
    init(duration: Int) {
        self.preset = MeditationPreset(
            title: "Meditation",
            description: "A \(duration / 60)-minute meditation session for relaxation and focus.",
            minutes: duration / 60,
            symbol: "timer",
            audioFileName: nil,
            hasAudio: false,
            tags: ["Custom Duration", "Focus", "Relaxation"]
        )
        _model = .init(wrappedValue: MeditationSessionModel(duration: duration))
    }

    var body: some View {
        ZStack {
            // Background matching app theme
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Back Button - positioned at the top
                HStack {
                    Button(action: {
                        // Add haptic feedback
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back to Meditation")
                                .font(.custom("AnekGujarati-Medium", size: 16))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Back to meditation selection")
                    .accessibilityHint("Returns to the main meditation menu")
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Enhanced Header section - left aligned
                        headerSection
                    
                        // Enhanced Progress Ring
                        progressSection
                    

                    
                        // Enhanced Transport Section
                        transportSection
                    
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { 
            // Don't auto-start meditation
        }
        .onChange(of: model.finished) { _, finished in
            guard finished else { return }
            sessionDuration = TimeInterval(model.total - model.remaining)
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCompletionSheet = true
            }
        }

        .sheet(isPresented: $showCompletionSheet, onDismiss: {
            dismiss()
        }) {
            MeditationCompletionSheet(streak: streak, preset: preset, sessionDuration: sessionDuration)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helper Functions
    
    private func tintColor(for preset: MeditationPreset) -> Color {
        // Use a consistent meditation color
        return Color(red: 0.56, green: 0.59, blue: 0.99)
    }
    
    // MARK: - Enhanced Header Section - Left Aligned
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(preset.title)
                .font(.custom("Amagro-Bold", size: 24))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if !preset.description.isEmpty {
                Text(preset.description)
                    .font(.custom("AnekGujarati-Regular", size: 17))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Enhanced Progress Section - Left Aligned
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Real-time progress bar
            VStack(spacing: 12) {
                // Progress bar container - Apple Media Player style
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(tintColor(for: preset))
                        .frame(width: max(0, min(1, currentProgress)) * (UIScreen.main.bounds.width - 64), height: 4)
                        .animation(.easeInOut(duration: 0.1), value: currentProgress)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                // Progress text and time
                HStack {
                    if model.total > 0 {
                        // Current time / Total time
                        Text(timeString(model.total - model.remaining))
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("/")
                            .font(.custom("AnekGujarati-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(timeString(model.total))
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        // No duration
                        Text("∞")
                            .font(.custom("AnekGujarati-Bold", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Status text
                    Text(currentStatusText)
                        .font(.custom("AnekGujarati-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Enhanced Duration Section - Left Aligned
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Session Duration")
                .font(.custom("AnekGujarati-Bold", size: 20))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(presets.enumerated()), id: \.offset) { index, duration in
                    let selected = duration == preset.minutes
                    
                    if selected {
                        Button {
                            // Duration is fixed for meditation presets
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text("\(duration)m")
                                .font(.custom("AnekGujarati-Bold", size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            LinearGradient(
                                                colors: [tintColor(for: preset).opacity(0.8), tintColor(for: preset).opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(tintColor(for: preset).opacity(0.9), lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: tintColor(for: preset).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(true)
                        .accessibilityLabel("Session duration: \(duration) minutes")
                    } else {
                        Button {
                            // Duration is fixed for meditation presets
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text("\(duration)m")
                                .font(.custom("AnekGujarati-Medium", size: 15))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                        .disabled(true)
                        .accessibilityLabel("Session duration: \(duration) minutes")
                    }
                }
                
                // Custom duration button (disabled for meditation presets)
                Button {
                    // Custom duration not available for meditation presets
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "timer")
                            .font(.system(size: 16, weight: .medium))
                        Text("Custom")
                            .font(.custom("AnekGujarati-Medium", size: 15))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .disabled(true)
                .accessibilityLabel("Custom duration not available for meditation presets")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Session Duration")
    }
    
    // MARK: - Enhanced Transport Section - Redesigned Buttons
    private var transportSection: some View {
        VStack(spacing: 24) {
            // Main play/pause button - redesigned
            Button {
                if model.isRunning {
                    model.pause()
                } else {
                    model.start()
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor(for: preset).opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // Main button background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor(for: preset), tintColor(for: preset).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: tintColor(for: preset).opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    // Play/Pause icon
                    if model.isRunning {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    }
                }
            }
            .frame(width: 140, height: 140)
            .accessibilityLabel(model.isRunning ? "Pause meditation" : "Start meditation")
            .accessibilityHint(model.isRunning ? "Pauses the current meditation" : "Starts the meditation session")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    


    // MARK: - Subviews

    // MARK: - Computed Properties
    
    private var currentProgress: Double {
        return model.finished ? 1 : model.progress
    }
    
    private var currentStatusText: String {
        return model.isRunning ? "In progress" : (model.finished ? "Completed" : "Paused")
    }



    // MARK: - Utils

    private func timeString(_ s: Int) -> String {
        let m = s / 60, ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }
}

// MARK: - Components

// private struct DurationPill: View {
//     let seconds: Int
//     let hasAudio: Bool
    
//     var body: some View {
//         let m = max(1, seconds) / 60
//         HStack(spacing: 6) {
//             Image(systemName: hasAudio ? "waveform" : "timer")
//             Text("\(m) min").font(.subheadline.weight(.semibold))
//             if hasAudio {
//                 Text("•")
//                 Text("Guided").font(.caption.weight(.medium))
//             }
//         }
//         .padding(.vertical, 6).padding(.horizontal, 10)
//         .background(Capsule().fill(hasAudio ? Color.orange.opacity(0.12) : Color.blue.opacity(0.12)))
//         .foregroundStyle(hasAudio ? .orange : .blue)
//         .accessibilityElement(children: .combine)
//         .accessibilityLabel("Duration \(m) minutes\(hasAudio ? ", guided meditation with audio" : "")")
//     }
// }

// private struct ToggleSoundButton: View {
//     @State private var muted = false
//     var body: some View {
//         Button {
//             muted.toggle()
//             #if os(iOS)
//             UIImpactFeedbackGenerator(style: .light).impactOccurred()
//             #endif
//         } label: {
//             Label(muted ? "Muted" : "Sound",
//                   systemImage: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
//         }
//         .buttonStyle(.bordered)
//         .controlSize(.regular)
//         .foregroundStyle(.primary)
//         .hapticsOnTap(.selection)
//     }
// }

//private struct KeepAwakeToggle: View {
//    @State private var keepAwake = true
//    var body: some View {
//        Button {
//            keepAwake.toggle()
//            #if os(iOS)
//            UIApplication.shared.isIdleTimerDisabled = keepAwake
//            #endif
//        } label: {
//            Image(systemName: keepAwake ? "moon.zzz.fill" : "moon")
//        }
//        .accessibilityLabel(keepAwake ? "Keep screen awake" : "Allow auto-lock")
//    }
//}

// MARK: - Audio Components

private struct VolumeControlSheet: View {
    @ObservedObject var engine: MeditationAudioEngine
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Volume slider
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .foregroundStyle(.secondary)
                        
                        Slider(value: Binding(
                            get: { engine.volume },
                            set: { engine.volume = $0 }
                        ), in: 0...1)
                        .tint(.blue)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Volume: \(Int(engine.volume * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Mute toggle
                Toggle("Mute Audio", isOn: $engine.isMuted)
                    .tint(.blue)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Audio Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Completion Sheet

private struct CompletionSheet: View {
    @ObservedObject var streak: StreakStore
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        VStack(spacing: 18) {
            // Header row with Share on the right (primary Done at the bottom)
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 6) { // Increased from 2 to 6 for better HIG spacing
                        Text("Great job!").font(.title3.weight(.semibold))
                        Text("Meditation complete").foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ShareLink(item: shareText,
                          preview: SharePreview("Meditation Streak",
                                                image: Image(systemName: "flame.fill"))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .hapticsOnTap(.light)
            }

            HStack(spacing: 14) {
                statCard(title: "Current Streak",
                         value: dayString(streak.streak),
                         symbol: "flame.fill", tint: .orange)
                statCard(title: "Best",
                         value: dayString(streak.bestStreak),
                         symbol: "trophy.fill", tint: .yellow)
            }

            if let last = streak.lastCompletionDate {
                Text("Last session: \(formatted(last))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Primary action, full-width at bottom — dismiss SHEET only.
            Button {
                dismissSheet()
            } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 4)
            .hapticsOnTap(.success)
        }
        .padding(20)
    }

    private var shareText: String {
        "I just meditated • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🧘‍♀️"
    }

    private func statCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            .foregroundStyle(tint)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(.thinMaterial))
    }

    private func formatted(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    private func dayString(_ n: Int) -> String {
        "\(max(n, 0)) " + (n == 1 ? "day" : "days")
    }
}

// MARK: - Meditation Completion Sheet

private struct MeditationCompletionSheet: View {
    @ObservedObject var streak: StreakStore
    let preset: MeditationPreset
    let sessionDuration: TimeInterval
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        VStack(spacing: 24) {
            // Header row with Share on the right
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Great job!")
                            .font(.custom("Amagro-Bold", size: 24))
                            .foregroundColor(.white)
                        Text("Meditation complete")
                            .font(.custom("AnekGujarati-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                ShareLink(item: shareText,
                          preview: SharePreview("Meditation Session Streak",
                                                image: Image(systemName: "flame.fill"))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.custom("AnekGujarati-Medium", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                .hapticsOnTap(.light)
            }

            // Session info card
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(red: 0.56, green: 0.59, blue: 0.99))
                    Text("\(preset.title) Session")
                        .font(.custom("Amagro-Bold", size: 18))
                        .foregroundColor(.white)
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.blue)
                    Text("Duration: \(formatDuration(sessionDuration))")
                        .font(.custom("AnekGujarati-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            HStack(spacing: 16) {
                statCard(title: "Current Streak",
                         value: dayString(streak.streak),
                         symbol: "flame.fill", tint: .orange)
                statCard(title: "Best",
                         value: dayString(streak.bestStreak),
                         symbol: "trophy.fill", tint: .yellow)
            }

            if let last = streak.lastCompletionDate {
                Text("Last session: \(formatted(last))")
                    .font(.custom("AnekGujarati-Regular", size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Primary action button
            Button {
                dismissSheet()
            } label: {
                Text("Done")
                    .font(.custom("AnekGujarati-Bold", size: 17))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
            }
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.56, green: 0.59, blue: 0.99).opacity(0.8), Color(red: 0.56, green: 0.59, blue: 0.99).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color(red: 0.56, green: 0.59, blue: 0.99).opacity(0.9), lineWidth: 1.5)
            )
            .shadow(color: Color(red: 0.56, green: 0.59, blue: 0.99).opacity(0.3), radius: 8, x: 0, y: 4)
            .hapticsOnTap(.success)
        }
        .padding(24)
        .background(Color(hex: "#1A2B7C"))
    }

    private var shareText: String {
        "I just completed a \(preset.title) meditation • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🧘‍♀️"
    }

    private func statCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                Text(title)
                    .font(.custom("AnekGujarati-Medium", size: 14))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            .foregroundStyle(tint)
            Text(value)
                .font(.custom("Amagro-Bold", size: 20))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func formatted(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    private func dayString(_ n: Int) -> String {
        "\(max(n, 0)) " + (n == 1 ? "day" : "days")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
}

#Preview {
    MeditationSessionView(preset: MeditationPreset(
        title: "Quick Reset",
        description: "A quick 2-minute meditation to reset your mind.",
        minutes: 2,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Quick", "Reset", "Focus"]
    ))
}
