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
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep Timer")
                .font(.custom("Amagro-Bold", size: 20))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(presets.enumerated()), id: \.element) { index, duration in
                    let selected = duration == engine.selectedDuration
                    
                    if selected {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
                                .font(.custom("AnekGujarati-Bold", size: 14))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    } else {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
                                .font(.custom("AnekGujarati-Medium", size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    }
                }
                
                // Custom duration button
                Button {
                    showCustom = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 14, weight: .medium))
                        Text("Custom")
                            .font(.custom("AnekGujarati-Medium", size: 14))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .accessibilityLabel("Set custom duration")
            }
        }
        .accessibilityLabel("Sleep Timer")
    }
    
    // MARK: - Volume Section
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Volume")
                .font(.custom("Amagro-Bold", size: 20))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                // Custom Mute button
                Button {
                    engine.isMuted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: engine.isMuted ? 
                                        [Color.red.opacity(0.3), Color.red.opacity(0.1)] :
                                        [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        engine.isMuted ? Color.red.opacity(0.4) : Color.white.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                        
                        Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.2.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(engine.isMuted ? .red : .white)
                    }
                    .frame(width: 56, height: 56)
                    .shadow(color: engine.isMuted ? Color.red.opacity(0.3) : Color.white.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .accessibilityLabel(engine.isMuted ? "Unmute" : "Mute")
                
                // Custom Volume slider
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Spacer()
                        
                        Text("\(Int(engine.volume * 100))%")
                            .font(.custom("AnekGujarati-Medium", size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Image(systemName: "speaker.3.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Custom Volume Slider
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(0, CGFloat(engine.volume) * UIScreen.main.bounds.width * 0.4), height: 8)
                        
                        // Thumb
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color.white.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.white.opacity(0.3), radius: 4, x: 0, y: 2)
                            .offset(x: max(0, CGFloat(engine.volume) * UIScreen.main.bounds.width * 0.4 - 10))
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let width = UIScreen.main.bounds.width * 0.4
                                let percentage = max(0, min(1, value.location.x / width))
                                engine.volume = Float(percentage)
                            }
                    )
                }
                .frame(maxWidth: .infinity)
                
                // Custom AirPlay button
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    MPVolumeViewWrapper()
                        .frame(width: 56, height: 56)
                }
                .frame(width: 56, height: 56)
                .accessibilityLabel("AirPlay")
            }
        }
    }
    
    // MARK: - Transport Section
    private var transportSection: some View {
        HStack(spacing: 24) {
            Spacer()
            
            // Custom Stop button
            Button(role: .destructive) {
                sessionDuration = engine.elapsed
                engine.stop()
                showCompletionAlert = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                    
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.red)
                }
                .frame(width: 72, height: 72)
                .shadow(color: Color.red.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .accessibilityLabel("Stop session and show statistics")
            
            // Custom Play/Pause button
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.4), Color.white.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                        )
                    
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                        .offset(x: engine.isPlaying ? 0 : 2) // Slight offset for play button
                }
                .frame(width: 96, height: 96)
                .shadow(color: Color.white.opacity(0.3), radius: 16, x: 0, y: 8)
            }
            .accessibilityLabel(engine.isPlaying ? "Pause audio" : "Play audio")
            
            Spacer()
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Custom Duration Sheet
    private var customDurationSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Text("Set Custom Duration")
                        .font(.custom("Amagro-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        Text("Select minutes")
                            .font(.custom("AnekGujarati-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
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
                    }
                    
                    HStack(spacing: 20) {
                        // Custom Cancel button
                        Button("Cancel") {
                            showCustom = false
                        }
                        .font(.custom("AnekGujarati-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        
                        // Custom Set Duration button
                        Button("Set Duration") {
                            engine.selectedDuration = .minutes(customMinutes)
                            showCustom = false
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .font(.custom("AnekGujarati-Bold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .shadow(color: Color.white.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
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