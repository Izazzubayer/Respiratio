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
                VStack(spacing: 32) {
                    // Enhanced Header section
                    headerSection
                    
                    // Enhanced Progress Ring
                    progressSection
                    
                    // Enhanced Sleep Timer chips
                    sleepTimerSection
                    
                    // Enhanced Transport Section
                    transportSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
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
        case "White Noise": return Color(hex: "#4A90E2")
        case "Brown Noise": return Color(hex: "#E67E22")
        case "Theta Wave": return Color(hex: "#9B59B6")
        case "Beta Wave": return Color(hex: "#F1C40F")
        default: return Color(hex: "#4A90E2")
        }
    }
    
    // MARK: - Enhanced Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(noise.title)
                    .font(.custom("Amagro-Bold", size: 32))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            if !noise.summary.isEmpty {
                Text(noise.summary)
                    .font(.custom("AnekGujarati-Regular", size: 17))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Enhanced Progress Section
    private var progressSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Enhanced progress ring background
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 140, height: 140)
                
                ProgressRing(
                    progress: engine.progress,
                    isIndeterminate: engine.durationSeconds == nil && engine.isPlaying,
                    accent: tintColor(for: noise)
                )
                .frame(width: 140, height: 140)
                .accessibilityLabel(engine.isPlaying ? "Playing" : "Paused")
                .accessibilityValue(engine.durationSeconds == nil ? "Indeterminate" 
                                  : "\(Int(engine.progress * 100)) percent")
                
                // Center status indicator
                if engine.durationSeconds == nil {
                    Text("∞")
                        .font(.custom("AnekGujarati-Bold", size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Status text
            Text(engine.isPlaying ? "Now Playing" : "Ready to Play")
                .font(.custom("AnekGujarati-Medium", size: 16))
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // MARK: - Enhanced Sleep Timer Section
    private var sleepTimerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Timer")
                .font(.custom("Amagro-Bold", size: 22))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(presets.enumerated()), id: \.element) { index, duration in
                    let selected = duration == engine.selectedDuration
                    
                    if selected {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
                                .font(.custom("AnekGujarati-Bold", size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            LinearGradient(
                                                colors: [tintColor(for: noise).opacity(0.8), tintColor(for: noise).opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18)
                                                .stroke(tintColor(for: noise).opacity(0.9), lineWidth: 1.5)
                                        )
                                )
                                .shadow(color: tintColor(for: noise).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    } else {
                        Button {
                            engine.selectedDuration = duration
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: duration))
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
                        .accessibilityLabel("Set timer to \(label(for: duration))")
                    }
                }
                
                // Enhanced custom duration button
                Button {
                    showCustom = true
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
                .accessibilityLabel("Set custom duration")
            }
        }
        .accessibilityLabel("Sleep Timer")
    }
    
    // MARK: - Enhanced Transport Section
    private var transportSection: some View {
        HStack(spacing: 32) {
            Spacer()
            
            // Enhanced Stop button
            Button(role: .destructive) {
                sessionDuration = engine.elapsed
                engine.stop()
                showCompletionAlert = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.3), Color.red.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1.5)
                        )
                    
                    Image(systemName: "stop.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 104, height: 104)
            .accessibilityLabel("Stop audio")
            .accessibilityHint("Ends the current session")
            
            // Enhanced Play/Pause button
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    // Outer ring with enhanced glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor(for: noise).opacity(0.4), tintColor(for: noise).opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(tintColor(for: noise).opacity(0.6), lineWidth: 2.5)
                        )
                        .shadow(color: tintColor(for: noise).opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    // Inner circle with icon
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    // Play/Pause icon
                    if engine.isPlaying {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                            .offset(x: 2) // Slight offset for visual balance
                    }
                }
            }
            .frame(width: 120, height: 120)
            .accessibilityLabel(engine.isPlaying ? "Pause audio" : "Play audio")
            .accessibilityHint(engine.isPlaying ? "Pauses the current audio" : "Starts playing the audio")
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Enhanced Custom Duration Sheet
    private var customDurationSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#1A2B7C")
                    .ignoresSafeArea()
                
                VStack(spacing: 36) {
                    Text("Set Custom Duration")
                        .font(.custom("Amagro-Bold", size: 26))
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
                            engine.selectedDuration = .minutes(customMinutes)
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
                                        colors: [tintColor(for: noise).opacity(0.8), tintColor(for: noise).opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(tintColor(for: noise).opacity(0.9), lineWidth: 1.5)
                                )
                        )
                        .shadow(color: tintColor(for: noise).opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 36)
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