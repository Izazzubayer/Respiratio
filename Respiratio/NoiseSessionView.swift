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
                    // Enhanced Header section - left aligned
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
        .navigationBarHidden(true)
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
    
    // MARK: - Enhanced Header Section - Left Aligned
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(noise.title)
                .font(.custom("Amagro-Bold", size: 32))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            if !noise.summary.isEmpty {
                Text(noise.summary)
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
            // Audio frequency progress bar
            VStack(spacing: 12) {
                // Progress bar container
                ZStack {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 80)
                    
                    // Audio frequency bars
                    HStack(spacing: 3) {
                        ForEach(0..<32, id: \.self) { index in
                            let barHeight = getBarHeight(for: index, progress: engine.progress)
                            
                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            tintColor(for: noise),
                                            tintColor(for: noise).opacity(0.7)
                                        ],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(width: 8, height: barHeight)
                                .animation(.easeInOut(duration: 0.3), value: barHeight)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                }
                
                // Progress text
                HStack {
                    if engine.durationSeconds == nil {
                        Text("∞")
                            .font(.custom("AnekGujarati-Bold", size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("\(Int(engine.progress * 100))%")
                            .font(.custom("AnekGujarati-Bold", size: 18))
                            .foregroundColor(tintColor(for: noise))
                    }
                    
                    Spacer()
                    
                    // Status text
                    Text(engine.isPlaying ? "Now Playing" : "Ready to Play")
                        .font(.custom("AnekGujarati-Medium", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helper function for bar heights
    private func getBarHeight(for index: Int, progress: Double) -> CGFloat {
        let baseHeight: CGFloat = 20
        let maxHeight: CGFloat = 60
        
        // Calculate how much of the progress bar this index represents
        let barProgress = Double(index) / 31.0 // 0 to 1 across 32 bars (0-31)
        
        // Only show bars up to the current progress
        if barProgress > progress {
            return baseHeight
        }
        
        // Create a wave-like pattern that's more pronounced for active bars
        let waveOffset = sin(Double(index) * 0.4) * 0.4
        let progressIntensity = 1.0 - (barProgress / progress) // Higher intensity for earlier bars
        
        // Calculate height based on progress and wave pattern
        let progressHeight = baseHeight + (maxHeight - baseHeight) * progressIntensity
        let waveHeight = progressHeight * (1.0 + waveOffset)
        
        // Ensure height is within bounds
        return max(baseHeight, min(maxHeight, waveHeight))
    }
    
    // MARK: - Enhanced Sleep Timer Section - Left Aligned
    private var sleepTimerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Timer")
                .font(.custom("Amagro-Bold", size: 22))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("Sleep Timer")
    }
    
    // MARK: - Enhanced Transport Section - Redesigned Buttons
    private var transportSection: some View {
        VStack(spacing: 24) {
            // Main play/pause button - redesigned
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor(for: noise).opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // Main button background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tintColor(for: noise), tintColor(for: noise).opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: tintColor(for: noise).opacity(0.4), radius: 20, x: 0, y: 10)
                    
                    // Play/Pause icon
                    if engine.isPlaying {
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
            .accessibilityLabel(engine.isPlaying ? "Pause audio" : "Play audio")
            .accessibilityHint(engine.isPlaying ? "Pauses the current audio" : "Starts playing the audio")
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