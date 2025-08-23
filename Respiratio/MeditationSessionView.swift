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
    @StateObject private var model: MeditationSessionModel
    @StateObject private var audioEngine = MeditationAudioEngine.shared
    @StateObject private var streak = StreakStore()

    @Environment(\.dismiss) private var dismiss
    @State private var showCongrats = false
    @State private var showVolumeControls = false
    
    private let preset: MeditationPreset

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
            LinearGradient(colors: [Color(.systemBackground),
                                    Color(.secondarySystemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 32) {
                header

                // Clean, Apple HIG-compliant progress ring
                ZStack {
                    // Background ring - HIG standard sizing
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 12)
                        .frame(width: 200, height: 200)

                    // Progress ring - clean single color
                    Circle()
                        .trim(from: 0, to: currentProgress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 200, height: 200)
                        .animation(.easeInOut(duration: 0.5), value: currentProgress)
                        .accessibilityHidden(true)

                    // Center content with proper visual hierarchy
                    VStack(spacing: 6) {
                        // Properly sized timer - HIG standard
                        Text(currentTimeString)
                            .font(.system(size: 28, weight: .medium, design: .default))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())
                        
                        // Secondary status - HIG typography scale
                        Text(currentStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .contentTransition(.opacity)
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentStatusText)
                }

                // Simplified controls without speed control
                simplifiedControls

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { KeepAwakeToggle().hapticsOnTap(.selection) }
        }
        .onAppear {
            setupSession()
        }
        .onDisappear {
            cleanupSession()
        }
        .onChange(of: model.finished) { _, finished in
            guard finished else { return }
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCongrats = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .meditationCompleted)) { _ in
            model.stop()
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCongrats = true
            }
        }
        .sheet(isPresented: $showVolumeControls) {
            VolumeControlSheet(engine: audioEngine)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        }
        // ✅ Dismiss order: Sheet first, THEN pop the session in onDismiss
        .sheet(isPresented: $showCongrats, onDismiss: {
            dismiss()
        }) {
            CompletionSheet(streak: streak)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Label(preset.title, systemImage: preset.symbol)
                .foregroundStyle(.primary)
                .font(.headline)
            Spacer()
            HStack(spacing: 8) {
                if preset.hasAudio {
                    Button {
                        showVolumeControls.toggle()
                    } label: {
                        Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Audio controls")
                }
//                DurationPill(seconds: model.total, hasAudio: preset.hasAudio)
            }
        }
        .padding(.horizontal)
    }

    // Clean, simplified controls following Apple HIG
    private var simplifiedControls: some View {
        VStack(spacing: 24) {
            // Primary transport controls - simple meditation timer
            HStack(spacing: 20) {
                // Main Play/Pause button - prominent and centered
                Button {
                    if preset.hasAudio {
                        audioEngine.isPlaying ? audioEngine.pause() : audioEngine.play()
                    } else {
                        model.isRunning ? model.pause() : model.start()
                    }
                } label: {
                    Label(currentPlayButtonText, systemImage: currentPlayButtonIcon)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44) // HIG minimum tap target
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .hapticsOnTap(.soft)
            }
            
            // Secondary control - just Stop button
            Button(role: .destructive) { 
                if preset.hasAudio {
                    audioEngine.stop()
                }
                model.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44) // HIG minimum tap target
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .hapticsOnTap(.rigid)
        }
        .padding(.horizontal, 24) // HIG standard margins
    }

    private var secondaryRow: some View {
        HStack(spacing: 16) {
//            ToggleSoundButton()
//            Spacer()
//
//            .buttonStyle(.plain)
//            .foregroundStyle(.primary)
//            .opacity(0.7)
//            .disabled(model.finished)
//            .hapticsOnTap(.light)
        }
        .padding(.horizontal)
    }

    // MARK: - Computed Properties
    
    private var currentProgress: Double {
        if preset.hasAudio {
            return audioEngine.progress
        } else {
            return model.finished ? 1 : model.progress
        }
    }
    
    // Removed - using single color now for cleaner HIG-compliant design
    
    private var currentTimeString: String {
        if preset.hasAudio {
            return timeString(Int(audioEngine.remainingTime))
        } else {
            return timeString(model.remaining)
        }
    }
    
    private var currentStatusText: String {
        if preset.hasAudio {
            if audioEngine.isPlaying {
                return "Guided meditation"
            } else if audioEngine.currentTime > 0 {
                return "Paused"
            } else {
                return "Ready to begin"
            }
        } else {
            return model.isRunning ? "In progress" : (model.finished ? "Completed" : "Paused")
        }
    }
    
    private var currentPlayButtonText: String {
        if preset.hasAudio {
            return audioEngine.isPlaying ? "Pause" : "Play"
        } else {
            return model.isRunning ? "Pause" : "Start"
        }
    }
    
    private var currentPlayButtonIcon: String {
        if preset.hasAudio {
            return audioEngine.isPlaying ? "pause.fill" : "play.fill"
        } else {
            return model.isRunning ? "pause.fill" : "play.fill"
        }
    }

    // MARK: - Session Management
    
    private func setupSession() {
        if preset.hasAudio, let audioFileName = preset.audioFileName {
            audioEngine.loadMeditation(fileName: audioFileName, title: preset.title)
        }
        
        model.start()
        
        // Configure audio session for ambient playback
        try? AVAudioSession.sharedInstance()
            .setCategory(.ambient, mode: .default, options: [.mixWithOthers])
    }
    
    private func cleanupSession() {
        if preset.hasAudio {
            audioEngine.stop()
        }
        model.pause()
        
        #if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = false
        #endif
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
