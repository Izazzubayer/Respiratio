import SwiftUI
import AVKit

struct NoiseSessionView: View {
    let noise: BackgroundNoise
    @StateObject private var engine = NoiseEngine.shared

    private let presets: [BNDuration] = [.fiveMin, .fifteenMin, .thirtyMin, .oneHour, .infinite]
    @State private var showCustom = false
    @State private var customMinutes = 20
    @State private var showStats = false
    @State private var sessionStats: SessionStats?

    // MARK: - Ring state derived from engine
    private var totalSeconds: TimeInterval? { engine.selectedDuration.timeInterval }
    private var progress: Double? {
        guard let total = totalSeconds, total > 0 else { return nil } // nil = infinite
        return min(max(engine.elapsed / total, 0), 1)
    }
    private var remainingText: String {
        guard let total = totalSeconds else { return "∞" }
        let remain = max(0, total - engine.elapsed)
        let m = Int(remain) / 60, s = Int(remain) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var body: some View {
        VStack(spacing: 24) {
            header
            mainPlayer
            sleepTimer
            volumeSection
            transportSection
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(noise.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { 
            engine.load(noise: noise)
            // Configure audio session for background playback
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        }
        .sheet(isPresented: $showCustom) { customDurationSheet }
        .sheet(isPresented: $showStats) { statsSheet }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !noise.summary.isEmpty {
                Text(noise.summary)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Main Player (Redesigned - No duplicate play button)
    private var mainPlayer: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                    .frame(width: 140, height: 140)
                
                // Progress circle
                if let p = progress {
                    Circle()
                        .trim(from: 0, to: CGFloat(p))
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                } else {
                    // Infinite mode - rotating arc
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(engine.isPlaying ? 360 : 0))
                        .frame(width: 140, height: 140)
                        .animation(engine.isPlaying ? .linear(duration: 2).repeatForever(autoreverses: false) : .default,
                                   value: engine.isPlaying)
                }
                
                // Status indicator (no play button)
                VStack(spacing: 4) {
                    Image(systemName: engine.isPlaying ? "speaker.wave.3.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .foregroundStyle(engine.isPlaying ? Color.accentColor : .secondary)
                    
                    if engine.isPlaying {
                        Text("Playing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Timer display
            Text(remainingText)
                .font(.title3.monospacedDigit().weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Sleep Timer (Redesigned)
    private var sleepTimer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep Timer")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(presets, id: \.self) { duration in
                    let selected = duration == engine.selectedDuration
                    Button {
                        engine.selectedDuration = duration
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text(label(for: duration))
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selected ? Color.accentColor : Color(.tertiarySystemFill))
                            )
                            .foregroundStyle(selected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Custom button
                Button {
                    showCustom = true
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Custom", systemImage: "timer")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.tertiarySystemFill))
                        )
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Volume Section (Redesigned)
    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                RoutePicker()
                    .frame(width: 28, height: 28)
            }
            
            VStack(spacing: 10) {
                // Volume slider
                HStack(spacing: 14) {
                    Button {
                        engine.isMuted.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.title3)
                            .foregroundStyle(engine.isMuted ? .secondary : .primary)
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    
                    Slider(
                        value: Binding(
                            get: { Double(engine.volume) },
                            set: { engine.volume = Float($0) }
                        ),
                        in: 0...1
                    )
                    .tint(Color.accentColor)
                    
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                }
            }
        }
    }

    // MARK: Transport Section (Redesigned)
    private var transportSection: some View {
        VStack(spacing: 12) {
            // Main play/pause button
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                    Text(engine.isPlaying ? "Pause" : "Play")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            
            // Stop button
            Button {
                stopSession()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                    Text("Stop")
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.red, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Custom duration sheet (Improved)
    private var customDurationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Custom Duration")
                    .font(.title2.weight(.bold))
                    .padding(.top, 20)
                
                VStack(spacing: 8) {
                    Text("Select duration in minutes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach(1...180, id: \.self) { m in 
                            Text("\(m) min").tag(m) 
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .clipped()
                }
                
                Text("Session will end after \(customMinutes) minute\(customMinutes == 1 ? "" : "s")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") { 
                        showCustom = false 
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.bordered)
                    
                    Button("Set Duration") {
                        engine.selectedDuration = .minutes(customMinutes)
                        showCustom = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: Stats Sheet
    private var statsSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Session Complete!")
                            .font(.title3.weight(.semibold))
                        Text(noise.title)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if let stats = sessionStats {
                    HStack(spacing: 14) {
                        statCard(title: "Duration", value: formatDuration(stats.duration), symbol: "timer", tint: .blue)
                        statCard(title: "Volume", value: "\(Int(stats.volume * 100))%", symbol: "speaker.wave.3", tint: .mint)
                    }
                }

                Button("Done") {
                    showStats = false
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(20)
        }
        .presentationDetents([.fraction(0.35), .medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: Helper Methods
    private func stopSession() {
        let stats = SessionStats(
            duration: engine.elapsed,
            volume: engine.volume
        )
        sessionStats = stats
        engine.stop()
        showStats = true
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }

    private func statCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
            }.foregroundStyle(tint)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(.thinMaterial))
    }

    private func label(for d: BNDuration) -> String {
        switch d {
        case .fiveMin: return "5m"
        case .fifteenMin: return "15m"
        case .thirtyMin: return "30m"
        case .oneHour: return "60m"
        case .infinite: return "∞"
        case .minutes(let m): return "\(m)m"
        }
    }
}

// MARK: - Helper Views and Types

private struct SessionStats {
    let duration: TimeInterval
    let volume: Float
}

private struct RoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView()
        v.activeTintColor = UIColor.label
        v.tintColor = UIColor.secondaryLabel
        return v
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}


