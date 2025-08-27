import SwiftUI
import AVKit
import MediaPlayer

struct NoiseSessionView: View {
    let noise: BackgroundNoise
    @StateObject private var engine = NoiseEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    private let presets: [BNDuration] = [.fiveMin, .fifteenMin, .thirtyMin, .oneHour, .infinite]
    @State private var showCustom = false
    @State private var customMinutes = 20
    @State private var showCompletionAlert = false
    @State private var sessionDuration: TimeInterval = 0
    
    var body: some View {
        ZStack {
            // Background matching app theme
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Description and tags
                    descriptionSection
                    
                    // Progress Ring
                    progressSection
                    
                    // Sleep Timer chips
                    sleepTimerSection
                    
                    // Volume controls
                    volumeSection
                    
                    // Transport controls
                    transportSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(noise.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { 
            engine.load(noise: noise)
        }
        .sheet(isPresented: $showCustom) { 
            customDurationSheet 
        }
        .alert("Session Complete", isPresented: $showCompletionAlert) {
            Button("Continue Listening") {
                // Stay on current screen, resume if desired
            }
            Button("Back to Menu") {
                dismiss()
            }
        } message: {
            Text("Great session! You listened to \(noise.title) for \(formatDuration(sessionDuration))." + 
                 (sessionDuration >= 300 ? "\n\nWell done on your focus time! 🎯" : ""))
        }
    }
    
    // MARK: - Helper Functions
    
    private func tintColor(for noise: BackgroundNoise) -> Color {
        switch noise.title {
        case "White Noise": return .blue
        case "Brown Noise": return .brown
        case "Theta Wave": return .purple
        case "Beta Wave": return .yellow
        default: return .blue
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !noise.summary.isEmpty {
                Text(noise.summary)
                    .font(.custom("AnekGujarati-Regular", size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            // Tag chips
            if !noise.tags.isEmpty {
                HStack {
                    ForEach(noise.tags, id: \.self) { tag in
                        Text(tag.capitalized)
                            .font(.custom("AnekGujarati-Medium", size: 12))
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Color.white.opacity(0.15)))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Progress Section
    private var progressSection: some View {
        VStack(spacing: 8) {
            ProgressRing(
                progress: engine.progress,
                isIndeterminate: engine.durationSeconds == nil && engine.isPlaying,
                accent: Color.white
            )
            .frame(width: 120, height: 120)
            .accessibilityLabel(engine.isPlaying ? "Playing" : "Paused")
            .accessibilityValue(engine.durationSeconds == nil ? "Indeterminate" 
                              : "\(Int(engine.progress * 100)) percent")
            
            Text(engine.durationSeconds == nil ? "∞" : "")
                .font(.custom("AnekGujarati-Regular", size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    // MARK: - Sleep Timer Section
    private var sleepTimerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timer")
                .font(.custom("Amagro-Bold", size: 20))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(presets.enumerated()), id: \.element) { index, duration in
                    let selected = duration == engine.selectedDuration
                    
                    if selected {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
                                .font(.custom("AnekGujarati-Bold", size: 14))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44) // HIG minimum tap target
                        }
                        .buttonStyle(BorderedProminentButtonStyle())
                        .controlSize(.small)
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    } else {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
                                .font(.custom("AnekGujarati-Medium", size: 14))
                                .frame(maxWidth: .infinity)
                                .frame(height: 44) // HIG minimum tap target
                        }
                        .buttonStyle(BorderedButtonStyle())
                        .controlSize(.small)
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    }
                }
                
                // Custom duration button
                Button {
                    showCustom = true
                } label: {
                    Label("Custom", systemImage: "timer")
                        .font(.custom("AnekGujarati-Medium", size: 14))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44) // HIG minimum tap target
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.small)
                .accessibilityLabel("Set custom duration")
            }
        }
        .accessibilityLabel("Sleep Timer")
    }
    
    // MARK: - Volume Section
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Volume")
                .font(.custom("Amagro-Bold", size: 20))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Mute button
                Button {
                    engine.isMuted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44) // HIG minimum tap target
                }
                .buttonStyle(BorderedButtonStyle())
                .accessibilityLabel(engine.isMuted ? "Unmute" : "Mute")
                
                // Volume slider
                Slider(value: $engine.volume, in: 0...1) {
                    Text("Volume")
                } minimumValueLabel: {
                    Image(systemName: "speaker.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                } maximumValueLabel: {
                    Image(systemName: "speaker.3.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .tint(.white)
                .accessibilityLabel("Volume")
                .accessibilityValue("\(Int(engine.volume * 100)) percent")
                
                // AirPlay route picker
                MPVolumeViewWrapper()
                    .frame(width: 44, height: 44)
                    .accessibilityLabel("AirPlay")
            }
        }
    }
    
    // MARK: - Transport Section
    private var transportSection: some View {
        HStack(spacing: 16) {
            Spacer()
            
            // Play/Pause button
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label(engine.isPlaying ? "Pause" : "Play",
                      systemImage: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.custom("AnekGujarati-Bold", size: 18))
                    .foregroundColor(.white)
            }
            .buttonStyle(BorderedProminentButtonStyle())
            .controlSize(.large)
            .accessibilityLabel(engine.isPlaying ? "Pause audio" : "Play audio")
            
            // Stop button
            Button(role: .destructive) {
                sessionDuration = engine.elapsed
                engine.stop()
                showCompletionAlert = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.custom("AnekGujarati-Bold", size: 16))
                    .foregroundColor(.white)
            }
            .buttonStyle(BorderedButtonStyle())
            .controlSize(.large)
            .tint(.red)
            .accessibilityLabel("Stop session and show statistics")
            
            Spacer()
        }
    }
    
    // MARK: - Custom Duration Sheet
    private var customDurationSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Set Custom Duration")
                        .font(.custom("Amagro-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach(1...180, id: \.self) { minutes in
                            Text("\(minutes) min")
                                .font(.custom("AnekGujarati-Regular", size: 16))
                                .foregroundColor(.white)
                                .tag(minutes)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 200)
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            showCustom = false
                        }
                        .font(.custom("AnekGujarati-Medium", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(BorderedButtonStyle())
                        
                        Button("Set Duration") {
                            engine.selectedDuration = .minutes(customMinutes)
                            showCustom = false
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .font(.custom("AnekGujarati-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .buttonStyle(BorderedProminentButtonStyle())
                    }
                }
                .padding()
            }
            .presentationDetents([.medium])
        }
    }
    
    // MARK: - Helper Methods
    private func label(for duration: BNDuration) -> String {
        switch duration {
        case .fiveMin: return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin: return "30m"
        case .oneHour: return "60m"
        case .infinite: return "∞"
        case .minutes(let m): return "\(m)m"
        }
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

// MARK: - AVRoutePickerView Wrapper
struct MPVolumeViewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let routePickerView = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        routePickerView.activeTintColor = UIColor.white
        routePickerView.tintColor = UIColor.white.withAlphaComponent(0.6)
        return routePickerView
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#Preview("Noise Session View") {
    NavigationStack {
        NoiseSessionView(noise: NoiseCatalog.all.first!)
    }
}