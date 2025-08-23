import SwiftUI
import Combine
import AVFoundation
import CoreHaptics

// MARK: - ViewModel

final class BreathingSessionModel: ObservableObject {
    let exercise: BreathingExercise
    let totalSeconds: Int

    @Published var remaining: Int
    @Published var isRunning = false        // starts paused
    @Published var finished = false

    @Published private(set) var phaseIndex = 0
    @Published private(set) var phaseRemaining: Int

    private var ticker: AnyCancellable?
    private let haptics: HapticBreathEngine

    init(exercise: BreathingExercise, totalSeconds: Int = 120) {
        self.exercise = exercise
        self.totalSeconds = max(1, totalSeconds)
        self.remaining = self.totalSeconds
        self.phaseRemaining = exercise.cycle.first?.seconds ?? 1

        switch exercise.title {
        case BreathingExercise.box.title:            self.haptics = .init(technique: .box)
        case BreathingExercise.equal.title:          self.haptics = .init(technique: .equal)
        case BreathingExercise.fourSevenEight.title: self.haptics = .init(technique: .fourSevenEight)
        case BreathingExercise.resonant.title:       self.haptics = .init(technique: .resonant)
        case BreathingExercise.triangle.title:       self.haptics = .init(technique: .triangle)
        default:                                     self.haptics = .init(technique: .equal)
        }
    }

    var currentPhase: BreathPhase { exercise.cycle[phaseIndex] }

    // User taps Play
    func start() {
        guard !isRunning && !finished else { return }
        isRunning = true
        
        // Only use traditional haptics for exercises that don't handle their own haptics
        // Box breathing and 4-7-8 breathing handle their own haptics internally
        if exercise.title != BreathingExercise.box.title && exercise.title != BreathingExercise.fourSevenEight.title {
            haptics.play(phase: chPhase(currentPhase.kind), duration: TimeInterval(phaseRemaining))
        }
        
        tick()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    // User taps Pause
    func pause() {
        isRunning = false
        ticker?.cancel(); ticker = nil
        haptics.stop()
    }

    func stop() { pause(); remaining = 0; finish() }

    private func tick() {
        guard isRunning else { return }
        remaining = max(remaining - 1, 0)
        phaseRemaining = max(phaseRemaining - 1, 0)
        if phaseRemaining == 0 { advancePhase() }
        if remaining == 0 { finish() }
    }

    private func advancePhase() {
        phaseIndex = (phaseIndex + 1) % exercise.cycle.count
        phaseRemaining = exercise.cycle[phaseIndex].seconds
        
        // Only use traditional haptics for exercises that don't handle their own haptics
        if exercise.title != BreathingExercise.box.title && exercise.title != BreathingExercise.fourSevenEight.title {
            haptics.play(phase: chPhase(currentPhase.kind), duration: TimeInterval(phaseRemaining))
        }
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

    private func chPhase(_ k: BreathPhase.Kind) -> HapticBreathEngine.Phase {
        switch k { case .inhale: return .inhale; case .hold: return .hold; case .exhale: return .exhale }
    }
}

// MARK: - View

struct BreathingSessionView: View {
    @StateObject private var model: BreathingSessionModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDone = false

    init(exercise: BreathingExercise, totalSeconds: Int = 120) {
        _model = .init(wrappedValue: .init(exercise: exercise, totalSeconds: totalSeconds))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                Spacer(minLength: 0)

                // Use custom visualizations for specific breathing techniques
                if model.exercise.title == BreathingExercise.box.title {
                    BoxBreathingView(
                        phase: model.currentPhase.kind,
                        phaseDuration: model.currentPhase.seconds,
                        secondsLeft: model.phaseRemaining,
                        tint: model.exercise.tint,
                        isRunning: model.isRunning,
                        phaseIndex: model.phaseIndex
                    )
                    .frame(width: 280, height: 280)
                } else if model.exercise.title == BreathingExercise.fourSevenEight.title {
                    TriangleBreathingView(
                        phase: model.currentPhase.kind,
                        phaseDuration: model.currentPhase.seconds,
                        secondsLeft: model.phaseRemaining,
                        tint: model.exercise.tint,
                        isRunning: model.isRunning,
                        phaseIndex: model.phaseIndex
                    )
                    .frame(width: 280, height: 280)
                } else {
                    SyncedBreathOrb(
                        phase: model.currentPhase.kind,
                        phaseDuration: model.currentPhase.seconds,
                        secondsLeft: model.phaseRemaining,
                        tint: model.exercise.tint,
                        isRunning: model.isRunning
                    )
                    .frame(width: 260, height: 260)
                }

                VStack(spacing: 8) {
                    PhaseChip(kind: model.currentPhase.kind, tint: model.exercise.tint)
                    Text(timeString(model.remaining))
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .padding(.top, 6)

                Spacer(minLength: 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Remove custom back button to avoid duplicate back button
        /*
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Breathing")
                    }
                    .foregroundStyle(.blue)
                    .font(.headline)
                }
            }
        }
        */
        .onAppear {
            // Do NOT auto-start; keep paused by default
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
        .onDisappear {
            model.pause()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .onChange(of: model.finished) { _, done in
            guard done else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { showDone = true }
        }
        .safeAreaInset(edge: .bottom) {
            BottomControls(
                isRunning: model.isRunning,
                startPause: { model.isRunning ? model.pause() : model.start() }, // shows Play initially
                stop: { model.stop() },
                tint: model.exercise.tint
            )
            .background(.ultraThinMaterial)
            .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
        }
        .sheet(isPresented: $showDone, onDismiss: { dismiss() }) {
            DoneSheet(exercise: model.exercise, total: model.totalSeconds)
                .presentationDetents([.fraction(0.35), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) { // Increased from 4 to 8 for better HIG spacing
                Text(model.exercise.title)
                    .font(.headline)
                // 👇 SHOW DESCRIPTION (1–3 lines)
                Text(model.exercise.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            HStack(spacing: 8) {
                DurationPill(color: model.exercise.tint, minutes: model.totalSeconds / 60)
                KeepAwakeToggle()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func timeString(_ s: Int) -> String {
        let m = s / 60, ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }
}

// MARK: - Synced visual (no outline, smooth/gradual)

/// Matches Core Haptics strength. Stays static when paused.
private struct SyncedBreathOrb: View {
    let phase: BreathPhase.Kind
    let phaseDuration: Int
    let secondsLeft: Int
    let tint: Color
    let isRunning: Bool          // NEW

    private var p: Double {
        guard phaseDuration > 0 else { return 0 }
        let done = Double(phaseDuration - secondsLeft)
        return min(max(done / Double(phaseDuration), 0), 1)
    }

    private var strength: Double {
        switch phase {
        case .inhale: return lerp(0.25, 1.00, p)
        case .hold:   return 0.45
        case .exhale: return lerp(1.00, 0.05, p)
        }
    }

    private var scale: CGFloat {
        switch phase {
        case .inhale: return CGFloat(lerp(0.65, 1.00, p))
        case .hold:   return 1.00
        case .exhale: return CGFloat(lerp(1.00, 0.65, p))
        }
    }

    private var innerOpacity: Double { lerp(0.28, 0.55, strength) }
    private var outerOpacity: Double { lerp(0.14, 0.26, strength) }
    private var glowRadius: CGFloat { CGFloat(lerp(8, 42, strength)) }
    private var glowOpacity: Double { lerp(0.10, 0.42, strength) }

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [tint.opacity(innerOpacity), tint.opacity(outerOpacity)],
                    center: .center, startRadius: 2, endRadius: 140
                )
            )
            .scaleEffect(scale)
            // Only animate while running; static while paused.
            .animation(isRunning ? .linear(duration: 0.95) : nil, value: secondsLeft)
            .shadow(color: tint.opacity(glowOpacity), radius: glowRadius)
            .overlay(
                Text("\(max(0, secondsLeft))")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            )
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        let name: String = {
            switch phase { case .inhale: return "Inhale"; case .hold: return "Hold"; case .exhale: return "Exhale" }
        }()
        return "\(name) \(secondsLeft) seconds remaining"
    }

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
}

// MARK: - Small components

private struct PhaseChip: View {
    let kind: BreathPhase.Kind
    let tint: Color
    var body: some View {
        let (text, icon): (String, String) = {
            switch kind {
            case .inhale: return ("Inhale", "arrow.down.circle")
            case .hold:   return ("Hold",   "pause.circle")
            case .exhale: return ("Exhale", "arrow.up.circle")
            }
        }()
        return Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill(tint.opacity(0.12)))
            .foregroundStyle(tint)
    }
}

private struct DurationPill: View {
    let color: Color
    let minutes: Int
    var body: some View {
        Label("\(minutes) min", systemImage: "timer")
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 6).padding(.horizontal, 10)
            .background(Capsule().fill(color.opacity(0.12)))
            .foregroundStyle(color)
    }
}

private struct BottomControls: View {
    let isRunning: Bool
    let startPause: () -> Void
    let stop: () -> Void
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Button(action: startPause) {
                Label(isRunning ? "Pause" : "Play",
                      systemImage: isRunning ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(tint)
            .controlSize(.large)

            Button(role: .destructive, action: stop) {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}

private struct DoneSheet: View {
    let exercise: BreathingExercise
    let total: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 6) { // Increased from 2 to 6 for better HIG spacing
                    Text("Nice breathing!").font(.title3.weight(.semibold))
                    Text(exercise.title).foregroundStyle(.secondary)
                }
                Spacer()
            }
            HStack(spacing: 12) {
                stat(title: "Duration", value: "\(total / 60) min", symbol: "timer", tint: .blue)
                stat(title: "Cycles", value: "\(cycleCount)", symbol: "repeat", tint: .mint)
            }
            Button { dismiss() } label: {
                Text("Done").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
    }

    private var cycleCount: Int {
        let secs = exercise.cycle.reduce(0) { $0 + $1.seconds }
        return max(total / max(secs, 1), 1)
    }

    private func stat(title: String, value: String, symbol: String, tint: Color) -> some View {
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
}
