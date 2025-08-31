import SwiftUI
import AVKit
import MediaPlayer

struct NoiseSessionView: View {
    let noise: BackgroundNoise
    @StateObject private var engine = NoiseEngine.shared
    @StateObject private var streak = StreakStore()
    @Environment(\.dismiss) private var dismiss
    
    private let presets: [BNDuration] = [.fiveMin, .fifteenMin, .thirtyMin, .oneHour, .infinite]
    @State private var showCustom = false
    @State private var customMinutes = 20
    @State private var showCompletionSheet = false
    @State private var sessionDuration: TimeInterval = 0
    
    // MARK: - Notification Listener
    @State private var exitNotificationObserver: NSObjectProtocol?
    @State private var tabChangeObserver: NSObjectProtocol?
    
    // MARK: - Notification Methods
    
    private func setupExitNotificationListener() {
        exitNotificationObserver = NotificationCenter.default.addObserver(
            forName: .exitToMainView,
            object: nil,
            queue: .main
        ) { notification in
            if let tab = notification.object as? NavTab, tab == .noise {
                dismiss()
            }
        }
        
        // Listen for tab changes to pause audio immediately
        tabChangeObserver = NotificationCenter.default.addObserver(
            forName: .tabDidChange,
            object: nil,
            queue: .main
        ) { _ in
            // Pause noise audio immediately when tab changes
            if engine.isPlaying {
                engine.stop()
            }
        }
    }
    
    private func cleanupExitNotificationListener() {
        if let observer = exitNotificationObserver {
            NotificationCenter.default.removeObserver(observer)
            exitNotificationObserver = nil
        }
        
        if let observer = tabChangeObserver {
            NotificationCenter.default.removeObserver(observer)
            tabChangeObserver = nil
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
                        // Add haptic feedback
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Back to Noise")
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
                    .accessibilityLabel("Back to noise selection")
                    .accessibilityHint("Returns to the main noise menu")
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
        }
        .navigationBarHidden(true)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        // Swipe right with minimal vertical movement
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }
                }
        )
        .onAppear { 
            engine.load(noise: noise)
            setupExitNotificationListener()
            // Set up completion callback
            engine.onSessionComplete = {
                sessionDuration = engine.elapsed
                _ = streak.registerCompletion()
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    showCompletionSheet = true
                }
            }
        }
        .onDisappear {
            cleanupExitNotificationListener()
        }
        .sheet(isPresented: $showCustom) { 
            customDurationSheet 
        }
        .sheet(isPresented: $showCompletionSheet, onDismiss: {
            dismiss()
        }) {
            NoiseCompletionSheet(streak: streak, noise: noise, sessionDuration: sessionDuration)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helper Functions
    
    private func tintColor(for noise: BackgroundNoise) -> Color {
        switch noise.title {
        case "White Noise": return Color(hex: "#4A90E2")
        case "Brown Noise": return Color(hex: "#4A90E2")
        case "Theta Wave": return Color(hex: "#4A90E2")
        case "Beta Wave": return Color(hex: "#4A90E2")
        default: return Color(hex: "#4A90E2")
        }
    }
    
    // MARK: - Enhanced Header Section - Left Aligned
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(noise.title)
                .font(.custom("Amagro-Bold", size: 24))
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
                        .fill(tintColor(for: noise))
                        .frame(width: max(0, min(1, engine.progress)) * (UIScreen.main.bounds.width - 64), height: 4)
                        .animation(.easeInOut(duration: 0.1), value: engine.progress)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                
                // Progress text and time
                HStack {
                    if let duration = engine.durationSeconds {
                        // Current time / Total time
                        Text(formatTime(engine.elapsed))
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("/")
                            .font(.custom("AnekGujarati-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text(formatTime(duration))
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        // Infinite duration
                        Text("∞")
                            .font(.custom("AnekGujarati-Bold", size: 18))
                            .foregroundColor(.white.opacity(0.7))
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
    
    // MARK: - Helper function to format time
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Enhanced Sleep Timer Section - Left Aligned
    private var sleepTimerSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sleep Timer")
                .font(.custom("AnekGujarati-Bold", size: 20))
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

// MARK: - Noise Completion Sheet

private struct NoiseCompletionSheet: View {
    @ObservedObject var streak: StreakStore
    let noise: BackgroundNoise
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
                        Text("Noise session complete")
                            .font(.custom("AnekGujarati-Regular", size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                Spacer()
                ShareLink(item: shareText,
                          preview: SharePreview("Noise Session Streak",
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
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(tintColor(for: noise))
                    Text("\(noise.title) Session")
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
                            colors: [tintColor(for: noise).opacity(0.8), tintColor(for: noise).opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(tintColor(for: noise).opacity(0.9), lineWidth: 1.5)
            )
            .shadow(color: tintColor(for: noise).opacity(0.3), radius: 8, x: 0, y: 4)
            .hapticsOnTap(.success)
        }
        .padding(24)
        .background(Color(hex: "#1A2B7C"))
    }

    private var shareText: String {
        "I just completed a \(noise.title) session • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🎧"
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
    
    private func tintColor(for noise: BackgroundNoise) -> Color {
        switch noise.title {
        case "White Noise": return Color(hex: "#4A90E2")
        case "Brown Noise": return Color(hex: "#E67E22")
        case "Theta Wave": return Color(hex: "#9B59B6")
        case "Beta Wave": return Color(hex: "#F1C40F")
        default: return Color(hex: "#4A90E2")
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