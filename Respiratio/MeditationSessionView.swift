//
//  MeditationSessionView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI
import Combine
import AVFoundation

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
    @StateObject private var model: MeditationSessionModel
    @StateObject private var streak = StreakStore()

    @Environment(\.dismiss) private var dismiss
    @State private var showCongrats = false

    init(duration: Int) {
        _model = .init(wrappedValue: MeditationSessionModel(duration: duration))
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(.systemBackground),
                                    Color(.secondarySystemBackground)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 28) {
                header

                // Progress ring + countdown
                ZStack {
                    Circle()
                        .stroke(lineWidth: 18)
                        .foregroundStyle(.quaternary)
                        .frame(width: 260, height: 260)

                    Circle()
                        .trim(from: 0, to: model.finished ? 1 : model.progress)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.blue, .mint, .green]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 260, height: 260)
                        .animation(.easeInOut(duration: 0.35), value: model.progress)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(timeString(model.remaining))
                            .font(.system(size: 56, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text(model.isRunning ? "In progress" : (model.finished ? "Completed" : "Paused"))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)

                controls
                secondaryRow

                Spacer()
            }
            .padding(.top, 8)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { KeepAwakeToggle().hapticsOnTap(.selection) }
        }
        .onAppear {
            model.start()
            try? AVAudioSession.sharedInstance()
                .setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        }
        .onDisappear {
            model.pause()
            #if os(iOS)
            UIApplication.shared.isIdleTimerDisabled = false   // make sure we re-enable autolock
            #endif
        }
        .onChange(of: model.finished) { _, finished in
            guard finished else { return }
            _ = streak.registerCompletion()
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                showCongrats = true
            }
        }
        // ✅ Dismiss order: Sheet first, THEN pop the session in onDismiss
        .sheet(isPresented: $showCongrats, onDismiss: {
            dismiss()
        }) {
            CompletionSheet(streak: streak)
                .presentationDetents([.fraction(0.45), .medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack {
            Label("Meditation", systemImage: "leaf.fill")
                .foregroundStyle(.primary)
                .font(.headline)
            Spacer()
            DurationPill(seconds: model.total)
        }
        .padding(.horizontal)
    }

    private var controls: some View {
        HStack(spacing: 16) {
            Button {
                model.isRunning ? model.pause() : model.start()
            } label: {
                Label(model.isRunning ? "Pause" : "Start",
                      systemImage: model.isRunning ? "pause.fill" : "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .hapticsOnTap(.soft)

            Button(role: .destructive) { model.stop() } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .hapticsOnTap(.rigid)
        }
        .padding(.horizontal)
    }

    private var secondaryRow: some View {
        HStack(spacing: 16) {
//            ToggleSoundButton()
//            Spacer()
//
//            .buttonStyle(.plain)
//            .foregroundStyle(.primary)
//            .opacity(0.7)
//            .disabled(model.finished)
//            .hapticsOnTap(.light)
        }
        .padding(.horizontal)
    }

    // MARK: - Utils

    private func timeString(_ s: Int) -> String {
        let m = s / 60, ss = s % 60
        return String(format: "%02d:%02d", m, ss)
    }
}

// MARK: - Components

private struct DurationPill: View {
    let seconds: Int
    var body: some View {
        let m = max(1, seconds) / 60
        HStack(spacing: 6) {
            Image(systemName: "timer")
            Text("\(m) min").font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 6).padding(.horizontal, 10)
        .background(Capsule().fill(Color.blue.opacity(0.12)))
        .foregroundStyle(.blue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Duration \(m) minutes")
    }
}

private struct ToggleSoundButton: View {
    @State private var muted = false
    var body: some View {
        Button {
            muted.toggle()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            Label(muted ? "Muted" : "Sound",
                  systemImage: muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .foregroundStyle(.primary)
        .hapticsOnTap(.selection)
    }
}

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

// MARK: - Completion Sheet

private struct CompletionSheet: View {
    @ObservedObject var streak: StreakStore
    @Environment(\.dismiss) private var dismissSheet

    var body: some View {
        VStack(spacing: 18) {
            // Header row with Share on the right (primary Done at the bottom)
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
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

            HStack(spacing: 14) {
                statCard(title: "Current Streak",
                         value: dayString(streak.streak),
                         symbol: "flame.fill", tint: .orange)
                statCard(title: "Best",
                         value: dayString(streak.bestStreak),
                         symbol: "trophy.fill", tint: .yellow)
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

    private var shareText: String {
        "I just meditated • Streak \(streak.streak) \(streak.streak == 1 ? "day" : "days")! 🧘‍♀️"
    }

    private func statCard(title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            .foregroundStyle(tint)
            Text(value).font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(.thinMaterial))
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
}
