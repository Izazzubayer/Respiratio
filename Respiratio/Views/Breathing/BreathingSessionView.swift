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
    
    // MARK: - Notification Listener
    @State private var exitNotificationObserver: NSObjectProtocol?
    @State private var tabChangeObserver: NSObjectProtocol?

    init(exercise: BreathingExercise, totalSeconds: Int = 120) {
        _model = .init(wrappedValue: .init(exercise: exercise, totalSeconds: totalSeconds))
    }
    
    // MARK: - Notification Methods
    
    private func setupExitNotificationListener() {
        exitNotificationObserver = NotificationCenter.default.addObserver(
            forName: .exitToMainView,
            object: nil,
            queue: .main
        ) { notification in
            if let tab = notification.object as? NavTab, tab == .breathing {
                dismiss()
            }
        }
        
        // Listen for tab changes to pause breathing session immediately
        tabChangeObserver = NotificationCenter.default.addObserver(
            forName: .tabDidChange,
            object: nil,
            queue: .main
        ) { _ in
            // Pause breathing session immediately when tab changes
            if model.isRunning {
                model.pause()
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
            // Background gradient matching meditation/noise screens
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header section matching meditation/noise style
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.exercise.title.uppercased())
                        .font(.custom("Amagro-Bold", size: 24))
                        .foregroundColor(.white)
                    
                    Text(model.exercise.description)
                        .font(.custom("AnekGujarati-Regular", size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)

                // Main content area
                VStack(spacing: 32) {
                    // Breathing visualization card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#4A90E2"), Color(hex: "#357ABD")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 24) {
                            // Use custom visualizations for specific breathing techniques
                            if model.exercise.title == BreathingExercise.box.title {
                                BoxBreathingView()
                                    .frame(width: 240, height: 240)
                            } else if model.exercise.title == BreathingExercise.fourSevenEight.title {
                                TriangleBreathingView(
                                    phase: model.currentPhase.kind,
                                    phaseDuration: model.currentPhase.seconds,
                                    secondsLeft: model.phaseRemaining,
                                    tint: .white,
                                    isRunning: model.isRunning,
                                    phaseIndex: model.phaseIndex
                                )
                                .frame(width: 240, height: 240)
                            } else {
                                // Simple fallback for other breathing techniques
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 220, height: 220)
                                    .overlay(
                                        Text("\(max(0, model.phaseRemaining))")
                                            .font(.custom("AnekGujarati-Bold", size: 32))
                                            .monospacedDigit()
                                            .foregroundColor(.white)
                                    )
                            }

                            // Phase indicator and timer
                            VStack(spacing: 16) {
                                PhaseChip(kind: model.currentPhase.kind, tint: .white)
                                Text(timeString(model.remaining))
                                    .font(.custom("AnekGujarati-Bold", size: 44))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                    // Session info card
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#6C5CE7"), Color(hex: "#5B4BC4")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Session Info")
                                    .font(.custom("AnekGujarati-Bold", size: 18))
                                    .foregroundColor(.white)
                                
                                Text("Duration: \(model.totalSeconds / 60) minutes")
                                    .font(.custom("AnekGujarati-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text("Current Phase: \(model.currentPhase.kind.rawValue.capitalized)")
                                    .font(.custom("AnekGujarati-Regular", size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemName: "timer.circle.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                        }
                        .padding(24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 0)
                }

                // Bottom controls
                VStack(spacing: 16) {
                    // Control buttons
                    HStack(spacing: 16) {
                        Button(action: { model.isRunning ? model.pause() : model.start() }) {
                            HStack(spacing: 8) {
                                Image(systemName: model.isRunning ? "pause.fill" : "play.fill")
                                Text(model.isRunning ? "Pause" : "Play")
                            }
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#4A90E2"))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: { model.stop() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.custom("AnekGujarati-Bold", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#E74C3C"))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 24)

                    // Keep awake toggle
                    KeepAwakeToggle()
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 && abs(value.translation.height) < 50 {
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                        dismiss()
                    }
                }
        )
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            setupExitNotificationListener()
        }
        .onDisappear {
            model.pause()
            cleanupExitNotificationListener()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .onChange(of: model.finished) { _, done in
            guard done else { return }
            withAnimation(.easeInOut(duration: 0.3)) { showDone = true }
        }
        .sheet(isPresented: $showDone, onDismiss: { dismiss() }) {
            DoneSheet(exercise: model.exercise, total: model.totalSeconds)
                .presentationDetents([.fraction(0.35), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func timeString(_ s: Int) -> String {
        let m = s / 60, ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }
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
            .font(.custom("AnekGujarati-Medium", size: 14))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
            )
            .foregroundColor(tint)
    }
}

private struct DoneSheet: View {
    let exercise: BreathingExercise
    let total: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#4CAF50"))
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nice breathing!")
                        .font(.custom("AnekGujarati-Bold", size: 20))
                        .foregroundColor(.white)
                    Text(exercise.title)
                        .font(.custom("AnekGujarati-Regular", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            
            HStack(spacing: 16) {
                stat(title: "Duration", value: "\(total / 60) min", symbol: "timer", tint: Color(hex: "#4A90E2"))
                stat(title: "Cycles", value: "\(cycleCount)", symbol: "repeat", tint: Color(hex: "#4CAF50"))
            }
            
            Button { dismiss() } label: {
                Text("Done")
                    .font(.custom("AnekGujarati-Bold", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#4A90E2"))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#6C5CE7"), Color(hex: "#5B4BC4")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    private var cycleCount: Int {
        let secs = exercise.cycle.reduce(0) { $0 + $1.seconds }
        return max(total / max(secs, 1), 1)
    }

    private func stat(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title)
                    .font(.custom("AnekGujarati-Medium", size: 12))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            .foregroundColor(tint)
            Text(value)
                .font(.custom("AnekGujarati-Bold", size: 18))
                .foregroundColor(.white)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
