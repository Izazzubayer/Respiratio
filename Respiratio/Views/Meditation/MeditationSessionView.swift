//
//  MeditationSessionView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI
import Combine
import AVFoundation
import AVKit

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
    @ObservedObject private var audioEngine = MeditationAudioEngine.shared
    @StateObject private var streak = StreakStore()
    @Environment(\.dismiss) private var dismiss
    
    private let presets: [Int] = [5, 15, 30, 60, 120]
    @State private var showCustom = false
    @State private var customMinutes = 20
    @State private var showCompletionSheet = false
    @State private var sessionDuration: TimeInterval = 0
    @State private var volume: Float = 0.8
    
    // MARK: - Notification Listener
    @State private var exitNotificationObserver: NSObjectProtocol?

    init(preset: MeditationPreset) {
        self.preset = preset
        _model = .init(wrappedValue: MeditationSessionModel(duration: Int(preset.duration)))
    }
    
    // Legacy initializer for compatibility
    init(duration: Int) {
        self.preset = MeditationPreset(
            title: "Meditation",
            description: "A \(duration / 60)-minute meditation session for relaxation and focus.",
            duration: TimeInterval(duration),
            category: .mindfulness,
            difficulty: duration <= 300 ? .beginner : (duration <= 900 ? .intermediate : .advanced),
            symbol: "timer",
            audioFileName: nil,
            hasAudio: false,
            tags: ["Custom Duration", "Focus", "Relaxation"]
        )
        _model = .init(wrappedValue: MeditationSessionModel(duration: duration))
    }
    
    // MARK: - Notification Methods
    
    private func setupExitNotificationListener() {
        exitNotificationObserver = NotificationCenter.default.addObserver(
            forName: .exitToMainView,
            object: nil,
            queue: .main
        ) { notification in
            if let tab = notification.object as? NavTab, tab == .meditation {
                dismiss()
            }
        }
    }
    
    private func cleanupExitNotificationListener() {
        if let observer = exitNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
            exitNotificationObserver = nil
        }
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
                        // Stop audio immediately when back button is tapped
                        if preset.hasAudio {
                            audioEngine.stop()
                        } else if model.isRunning {
                            model.pause()
                        }
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
                    VStack(spacing: 40) {
                        // Header section - left aligned
                        headerSection
                    
                        // Progress section - centered like Apple Media Player
                        progressSection
                    
                        // Transport Section - Apple Media Player style
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
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        // Stop audio immediately when swipe gesture is triggered
                        if preset.hasAudio {
                            audioEngine.stop()
                        } else if model.isRunning {
                            model.pause()
                        }
                        // Swipe right with minimal vertical movement
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }
                }
        )
        .onAppear {
            setupSession()
            setupExitNotificationListener()
            // Notify that meditation session has started
            NotificationCenter.default.post(name: .meditationSessionStarted, object: nil)
        }
        .onChange(of: model.finished) { _, finished in
            guard finished else { return }
            sessionDuration = TimeInterval(model.total - model.remaining)
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCompletionSheet = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .meditationCompleted)) { _ in
            if preset.hasAudio {
                audioEngine.stop()
            } else {
            model.stop()
            }
            sessionDuration = preset.hasAudio ? audioEngine.duration : TimeInterval(model.total)
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCompletionSheet = true
            }
        }
        .onDisappear {
            cleanupExitNotificationListener()
            // Stop audio immediately when view disappears
            if preset.hasAudio {
                audioEngine.stop()
            } else if model.isRunning {
                model.pause()
            }
            // Notify that meditation session has ended
            NotificationCenter.default.post(name: .meditationSessionEnded, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { _ in
            // Force UI update when audio route changes
            // This will refresh the audio output display
        }
        .sheet(isPresented: $showCustom) { 
            customDurationSheet
                .presentationBackground(Color(hex: "#1A2B7C"))
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showCompletionSheet, onDismiss: {
            dismiss()
            // Notify that meditation session has ended when completion sheet is dismissed
            NotificationCenter.default.post(name: .meditationSessionEnded, object: nil)
        }) {
            MeditationCompletionSheet(streak: streak, preset: preset, sessionDuration: sessionDuration)
                .presentationDetents([.fraction(0.65), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color(hex: "#1A2B7C"))
                .presentationCornerRadius(24)
        }
        .overlay(
            // Dark background overlay when sheet is presented
            Color.black.opacity(showCompletionSheet ? 0.25 : 0)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.3), value: showCompletionSheet)
        )
    }

    // MARK: - Helper Functions
    
    private func tintColor(for preset: MeditationPreset) -> Color {
        // Use a consistent meditation color
        return Color(red: 0.29, green: 0.56, blue: 0.89)
    }
    
    // MARK: - Audio Output Detection
    private var currentAudioOutputIcon: String {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        
        for output in outputs {
            switch output.portType {
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                return "airpods"
            case .headphones:
                return "headphones"
            case .airPlay:
                return "airplayaudio"
            case .builtInSpeaker:
                return "speaker.wave.3"
            default:
                break
            }
        }
        return "airplayaudio"
    }
    
    private var currentAudioOutputName: String {
        let session = AVAudioSession.sharedInstance()
        let outputs = session.currentRoute.outputs
        
        for output in outputs {
            switch output.portType {
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                // Check if it's AirPods specifically
                if output.portName.lowercased().contains("airpods") || 
                   output.portName.lowercased().contains("airpod") {
                    return "AirPods"
                } else if output.portName.lowercased().contains("bluetooth") {
                    return "Bluetooth"
                } else {
                    return output.portName.isEmpty ? "Bluetooth" : output.portName
                }
            case .headphones:
                return output.portName.isEmpty ? "Headphones" : output.portName
            case .airPlay:
                return output.portName.isEmpty ? "AirPlay" : output.portName
            case .builtInSpeaker:
                return "iPhone"
            default:
                break
            }
        }
        return "iPhone"
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
    
        // MARK: - Apple Media Player Style Progress Section
    private var progressSection: some View {
        VStack(spacing: 20) {
            // Progress bar with time display - Apple Media Player style
            VStack(spacing: 16) {
                // Progress bar container
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: max(0, min(1, currentProgress)) * (UIScreen.main.bounds.width - 64), height: 4)
                        .animation(.easeInOut(duration: 0.1), value: currentProgress)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                // Time display - Apple Media Player style
        HStack {
                if preset.hasAudio {
                        // Current time
                        Text(formatTime(audioEngine.currentTime))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Remaining time (negative format like Apple)
                        Text("-\(formatTime(audioEngine.duration - audioEngine.currentTime))")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    } else if model.total > 0 {
                        // Current time
                        Text(timeString(model.total - model.remaining))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Remaining time (negative format like Apple)
                        Text("-\(timeString(model.remaining))")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    } else {
                        // No duration
                        Text("∞")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
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
                    let selected = duration == Int(preset.duration / 60)
                    
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
    
    // MARK: - Apple Media Player Style Transport Section
    private var transportSection: some View {
        VStack(spacing: 32) {
            // Main playback controls - Apple Media Player style
            HStack(spacing: 40) {
                // Rewind 30 seconds button
                Button {
                    if preset.hasAudio {
                        audioEngine.skipBackward(30)
                    } else {
                        // For timer-based meditation, skip back 30 seconds
                        let newTime = max(0, model.total - model.remaining - 30)
                        model.remaining = model.total - newTime
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Image(systemName: "gobackward.30")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                            
                        }
                    }
                }
                .accessibilityLabel("Skip backward 30 seconds")
                
                // Main play/pause button - Original design (like noise player)
                Button {
                if preset.hasAudio {
                        if audioEngine.isPlaying {
                            audioEngine.pause()
                        } else {
                            audioEngine.play()
                        }
                    } else {
                        if model.isRunning {
                            model.pause()
                        } else {
                            model.start()
                        }
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
                        if preset.hasAudio {
                            if audioEngine.isPlaying {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 40, weight: .medium))
                                    .foregroundColor(.white)
                                    .offset(x: 2)
                            }
                        } else {
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
                }
                .accessibilityLabel(
                    preset.hasAudio 
                        ? (audioEngine.isPlaying ? "Pause guided meditation" : "Start guided meditation")
                        : (model.isRunning ? "Pause meditation" : "Start meditation")
                )
                
                // Fast forward 30 seconds button
                Button {
                    if preset.hasAudio {
                        audioEngine.skipForward(30)
                    } else {
                        // For timer-based meditation, skip forward 30 seconds
                        let newTime = min(model.total, model.total - model.remaining + 30)
                        model.remaining = model.total - newTime
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        VStack(spacing: 2) {
                            Image(systemName: "goforward.30")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .accessibilityLabel("Skip forward 30 seconds")
            }
            
            // Volume control - Apple Media Player style
            // VStack(spacing: 12) {
            //     HStack(spacing: 16) {
            //         // Low volume speaker icon
            //         Image(systemName: "speaker.wave.1")
            //             .font(.system(size: 16, weight: .medium))
            //             .foregroundColor(.white.opacity(0.8))
            //         
            //         // Volume slider
            //         Slider(value: $volume, in: 0...1) { editing in
            //             if editing {
            //             // Update volume when sliding
            //             if preset.hasAudio {
            //                 audioEngine.volume = volume
            //             }
            //         }
            //     }
            //         .accentColor(.white)
            //         
            //         // High volume speaker icon
            //         Image(systemName: "speaker.wave.3")
            //             .font(.system(size: 16, weight: .medium))
            //             .foregroundColor(.white.opacity(0.8))
            //     }
            //     .padding(.horizontal, 16)
            // }
            
            // Output device selector - Apple Media Player style
            HStack(spacing: 8) {
                Image(systemName: currentAudioOutputIcon)
                    .font(.system(size: 16, weight: .medium))
                Text(currentAudioOutputName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .overlay(
                // Native AirPlay button overlay
                AirPlayButton()
                    .frame(width: 200, height: 44)
                    .opacity(0.01) // Nearly invisible but tappable
            )
            .accessibilityLabel("Select audio output device")
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    // MARK: - Enhanced Custom Duration Sheet
    private var customDurationSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Set Custom Duration")
                        .font(.custom("Amagro-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 20) {
                        Text("Select minutes")
                            .font(.custom("AnekGujarati-Regular", size: 17))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Picker("Minutes", selection: $customMinutes) {
                            ForEach(1...180, id: \.self) { minutes in
                                Text("\(minutes) min")
                                    .font(.custom("AnekGujarati-Regular", size: 17))
                                    .foregroundColor(.white)
                                    .tag(minutes)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 200)
                    }
                    
                    HStack(spacing: 24) {
                        // Enhanced Cancel button
                        Button("Cancel") {
                            showCustom = false
                        }
                        .font(.custom("AnekGujarati-Medium", size: 17))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Enhanced Set Duration button
                        Button("Set Duration") {
                            showCustom = false
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .font(.custom("AnekGujarati-Bold", size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
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
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 36)
            }
            .presentationDetents([.medium])
        }
    }

    // MARK: - Subviews

    // MARK: - Computed Properties
    
    private var currentProgress: Double {
        if preset.hasAudio {
            return audioEngine.progress
        } else {
            return model.finished ? 1 : model.progress
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

    // MARK: - Session Management
    
    private func setupSession() {
        // Setup audio if this is a guided meditation
        if preset.hasAudio, let audioFileName = preset.audioFileName {
            audioEngine.loadMeditation(fileName: audioFileName, title: preset.title)
        }
        
        // Don't auto-start the meditation session
        // model.start()
    }

    // MARK: - Utils

    private func timeString(_ s: Int) -> String {
        let m = s / 60, ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - AirPlay Integration
    private func showAirPlayMenu() {
        #if os(iOS)
        // Create and present the native AirPlay route picker
        let routePicker = AVRoutePickerView()
        routePicker.backgroundColor = .clear
        routePicker.tintColor = .white
        
        // Find the button in the route picker and trigger it
        if let button = routePicker.subviews.first(where: { $0 is UIButton }) as? UIButton {
            button.sendActions(for: .touchUpInside)
        }
        #endif
    }
}

// MARK: - Native AirPlay Button
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePicker = AVRoutePickerView()
        routePicker.backgroundColor = .clear
        routePicker.tintColor = .white
        routePicker.activeTintColor = .white
        return routePicker
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // Update the view if needed
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
    
    private var shareText: String {
        "I just meditated • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🧘‍♀️"
    }

    var body: some View {
        VStack(spacing: 18) {
            // Header row with Share on the right (primary Done at the bottom)
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
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

            HStack(spacing: DesignSystem.Spacing.md) {
                StreakCard(
                    title: "Current Streak",
                    value: dayString(streak.streak),
                    symbol: "flame.fill",
                    tint: Color.orange
                )
                
                StreakCard(
                    title: "Best",
                    value: dayString(streak.bestStreak),
                    symbol: "trophy.fill",
                    tint: Color.yellow
                )
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

    // shareText function removed - now defined inside MeditationCompletionSheet

    // statCard function removed - now using StreakCard component from DesignSystem

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
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Header row with Share on the right
            HStack(spacing: DesignSystem.Spacing.sm) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Great job!")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(.white)
                        Text("Meditation complete")
                            .font(DesignSystem.Typography.caption1)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                ShareLink(item: shareText,
                          preview: SharePreview("Meditation Session Streak",
                                                image: Image(systemName: "flame.fill"))) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(DesignSystem.Typography.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(DesignSystem.Colors.overlayStrong)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .stroke(DesignSystem.Colors.overlayBorder, lineWidth: 1)
                        )
                }
                .hapticsOnTap(.light)
            }

            // Session info card
            SessionInfoCard(
                title: "\(preset.title) Session",
                duration: formatDuration(sessionDuration),
                brainIconColor: DesignSystem.Colors.primaryLight
            )

            HStack(spacing: DesignSystem.Spacing.md) {
                StreakCard(
                    title: "Current Streak",
                    value: dayString(streak.streak),
                    symbol: "flame.fill",
                    tint: Color.orange
                )
                
                StreakCard(
                    title: "Best",
                    value: dayString(streak.bestStreak),
                    symbol: "trophy.fill",
                    tint: Color.yellow
                )
            }

            if let last = streak.lastCompletionDate {
                Text("Last session: \(formatted(last))")
                    .font(.custom("AnekGujarati-Regular", size: 18))
                    .foregroundColor(.white.opacity(0.6))
            }

            // Primary action button
            PrimaryButton(title: "Done") {
                dismissSheet()
            }
            .hapticsOnTap(.success)
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            DesignSystem.Colors.primaryDark
                .ignoresSafeArea()
        )
    }

    private var shareText: String {
        "I just completed a \(preset.title) meditation • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🧘‍♀️"
    }

    // statCard function removed - now using StreakCard component from DesignSystem

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
        duration: TimeInterval(2 * 60), // 2 minutes in seconds
        category: .mindfulness,
        difficulty: .beginner,
        symbol: "timer",
        audioFileName: nil,
        hasAudio: false,
        tags: ["Quick", "Reset", "Focus"]
    ))
}
