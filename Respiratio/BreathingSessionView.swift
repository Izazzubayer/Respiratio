//
//  BreathingSessionView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI
import Combine
import AVFoundation

// MARK: - ViewModel (2 min total, pulsating only)
final class BreathingSessionModel: ObservableObject {
    let exercise: BreathingExercise
    let totalSeconds: Int

    @Published var remaining: Int
    @Published var isRunning = false
    @Published var finished = false

    // phase
    @Published private(set) var phaseIndex = 0
    @Published private(set) var phaseRemaining: Int

    private var ticker: AnyCancellable?

    init(exercise: BreathingExercise, totalSeconds: Int = 120) {
        self.exercise = exercise
        self.totalSeconds = max(1, totalSeconds)
        self.remaining = self.totalSeconds
        self.phaseRemaining = exercise.cycle.first?.seconds ?? 1
    }

    var currentPhase: BreathPhase { exercise.cycle[phaseIndex] }

    func start() {
        guard !isRunning && !finished else { return }
        isRunning = true
        tick()
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func pause() {
        isRunning = false
        ticker?.cancel()
        ticker = nil
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
        #if os(iOS)
        // subtle, intuitive haptics per phase
        switch exercise.cycle[phaseIndex].kind {
        case .inhale: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .hold:   UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .exhale: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        #endif
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

// MARK: - View (Apple‑style minimal)
struct BreathingSessionView: View {
    @StateObject private var model: BreathingSessionModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDone = false

    init(exercise: BreathingExercise, totalSeconds: Int = 120) {
        _model = .init(wrappedValue: .init(exercise: exercise, totalSeconds: totalSeconds))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemBackground),
                                    Color(.secondarySystemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 20) {
                header

                Spacer(minLength: 0)

                // Single pulsating circle — no progress ring.
                PulsatingCircle(
                    phase: model.currentPhase.kind,
                    phaseDuration: model.currentPhase.seconds,
                    secondsLeft: model.phaseRemaining,
                    tint: model.exercise.tint
                )
                .frame(width: 260, height: 260)

                // Small phase chip + big time (readable)
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
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            model.start()
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
        .onDisappear {
            model.pause()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
        }
        .onChange(of: model.finished) { done in
            guard done else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) { showDone = true }
        }
        .safeAreaInset(edge: .bottom) {
            BottomControls(
                isRunning: model.isRunning,
                startPause: { model.isRunning ? model.pause() : model.start() },
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

    // Header with title, duration pill, and keep‑awake
    private var header: some View {
        HStack(spacing: 12) {
            Label(model.exercise.title, systemImage: "wind")
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)
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

// MARK: - Components

/// The only visual driver: expands (inhale) → steady (hold) → contracts (exhale)
private struct PulsatingCircle: View {
    let phase: BreathPhase.Kind
    let phaseDuration: Int
    let secondsLeft: Int
    let tint: Color

    // progress 0→1 within current phase
    private var p: Double {
        guard phaseDuration > 0 else { return 0 }
        return Double(phaseDuration - secondsLeft) / Double(phaseDuration)
    }

    // scale curve — gentle and readable
    private var scale: CGFloat {
        switch phase {
        case .inhale: return CGFloat(0.65 + 0.35 * p)       // 65% → 100%
        case .hold:   return 1.0                             // steady
        case .exhale: return CGFloat(0.65 + 0.35 * (1 - p))  // 100% → 65%
        }
    }

    // subtle tint per phase (keeps things intuitive without words)
    private var fill: Color {
        switch phase {
        case .inhale: return tint.opacity(0.28)
        case .hold:   return tint.opacity(0.20)
        case .exhale: return tint.opacity(0.28)
        }
    }
    private var stroke: Color {
        switch phase {
        case .inhale: return tint.opacity(0.9)
        case .hold:   return tint.opacity(0.55)
        case .exhale: return tint.opacity(0.9)
        }
    }

    var body: some View {
        Circle()
            .fill(fill.gradient)
            .overlay(Circle().stroke(stroke, lineWidth: 3))
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.9), value: secondsLeft)
            .overlay(
                Text("\(secondsLeft)")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
            )
            .accessibilityLabel("\(phaseLabel) \(secondsLeft) seconds remaining")
    }

    private var phaseLabel: String {
        switch phase { case .inhale: "Inhale"; case .hold: "Hold"; case .exhale: "Exhale" }
    }
}

private struct PhaseChip: View {
    let kind: BreathPhase.Kind
    let tint: Color
    var body: some View {
        let (text, icon): (String, String) = {
            switch kind {
            case .inhale: return ("Inhale", "arrow.down.circle")   // down into lungs
            case .hold:   return ("Hold",   "pause.circle")
            case .exhale: return ("Exhale", "arrow.up.circle")     // up/out
            }
        }()
        return Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Capsule().fill(tint.opacity(0.12)))
            .foregroundStyle(tint)
            .accessibilityHidden(false)
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
                Label(isRunning ? "Pause" : "Start",
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
                VStack(alignment: .leading, spacing: 2) {
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
