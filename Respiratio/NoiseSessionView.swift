import SwiftUI
import AVKit

struct NoiseSessionView: View {
    let noise: BackgroundNoise
    @StateObject private var engine = NoiseEngine.shared

    private let presets: [BNDuration] = [.fiveMin, .fifteenMin, .thirtyMin, .oneHour, .infinite]
    @State private var showCustom = false
    @State private var customMinutes = 20

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
        ScrollView {
            VStack(spacing: 22) {
                header
                ring                         // ⬅️ NEW
                sleepTimer
                volume
                transport
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(noise.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { engine.load(noise: noise) }
        .sheet(isPresented: $showCustom) { customDurationSheet }
    }

    // MARK: Header
    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !noise.summary.isEmpty {
                Text(noise.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            FlexibleChips(data: noise.tags, spacing: 6, alignment: .leading) { tag in
                Text(tag.capitalized)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Progress Ring (NEW)
    private var ring: some View {
        VStack(spacing: 10) {
            ProgressRing(progress: progress, isPlaying: engine.isPlaying)
                .frame(width: 220, height: 220)
                .onTapGesture {
                    engine.isPlaying ? engine.pause() : engine.play()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .animation(.linear(duration: 0.9), value: engine.elapsed)

            Text(remainingText)
                .font(.title3.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
    }

    // MARK: Sleep timer
    private var sleepTimer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sleep Timer").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { d in
                        let selected = d == engine.selectedDuration
                        Button {
                            engine.selectedDuration = d
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(label(for: d))
                                .font(.subheadline.weight(.semibold))
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(selected ? Color.accentColor.opacity(0.20)
                                                       : Color(.tertiarySystemFill))
                                )
                                .foregroundStyle(selected ? Color.accentColor : Color.primary)
                        }
                    }
                    Button {
                        showCustom = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Label("Custom", systemImage: "timer")
                            .font(.subheadline.weight(.semibold))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Color(.tertiarySystemFill)))
                    }
                }
            }
        }
    }

    // MARK: Volume + AirPlay
    private var volume: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Volume").font(.headline)
                Spacer()
                RoutePicker().frame(width: 28, height: 28)
            }
            HStack(spacing: 12) {
                Button {
                    engine.isMuted.toggle()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: engine.isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.headline)
                        .foregroundStyle(engine.isMuted ? .secondary : .primary)
                }
                Slider(
                    value: Binding(
                        get: { Double(engine.volume) },
                        set: { engine.volume = Float($0) }
                    ),
                    in: 0...1
                )
                .tint(Color.accentColor)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Transport
    private var transport: some View {
        HStack(spacing: 16) {
            Spacer()
            Button {
                engine.isPlaying ? engine.pause() : engine.play()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    Text(engine.isPlaying ? "Pause" : "Play")
                        .fontWeight(.semibold)
                }
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                engine.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: Custom duration
    private var customDurationSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Text("Custom Duration").font(.title3.bold()).padding(.top, 10)
                Picker("Minutes", selection: $customMinutes) {
                    ForEach(1...180, id: \.self) { m in Text("\(m) min").tag(m) }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                Text("Session will end after \(customMinutes) minute\(customMinutes == 1 ? "" : "s").")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 12) {
                    Button("Cancel") { showCustom = false }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.bordered)
                    Button("Set") {
                        engine.selectedDuration = .minutes(customMinutes)
                        showCustom = false
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 20)
        }
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

// MARK: - Progress Ring pieces (NEW)

private struct ProgressRing: View {
    /// 0...1 for finite timers, nil for infinite (shows a rotating dash)
    let progress: Double?
    let isPlaying: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: 14)

            if let p = progress {
                Circle()
                    .trim(from: 0, to: CGFloat(p))
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            } else {
                ArcDash()
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(isPlaying ? 360 : 0))
                    .animation(isPlaying ? .linear(duration: 1.2).repeatForever(autoreverses: false) : .default,
                               value: isPlaying)
            }

            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(.blue)
                .background(
                    Circle().fill(Color.accentColor.opacity(0.12)).frame(width: 64, height: 64)
                )
        }
        .contentShape(Circle())
    }
}

/// Small arc used for the infinite mode spinner
private struct ArcDash: Shape {
    func path(in rect: CGRect) -> Path {
        let start: CGFloat = -.pi/2
        let end: CGFloat = start + .pi/3
        var p = Path()
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                 radius: min(rect.width, rect.height)/2,
                 startAngle: .radians(start),
                 endAngle: .radians(end),
                 clockwise: false)
        return p
    }
}

// Helpers
private struct FlexibleChips<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    init(data: Data, spacing: CGFloat, alignment: HorizontalAlignment, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data; self.spacing = spacing; self.alignment = alignment; self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let maxWidth = proxy.size.width
            let rows = buildRows(maxWidth: maxWidth)
            VStack(alignment: alignment, spacing: spacing) {
                ForEach(rows.indices, id: \.self) { i in
                    HStack(spacing: spacing) { ForEach(rows[i], id: \.self) { item in content(item) } }
                }
            }
        }
        .frame(minHeight: 0)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func buildRows(maxWidth: CGFloat) -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]; var width: CGFloat = 0; let padding: CGFloat = 22
        for item in data {
            let label = String(describing: item)
            let w = label.size(withAttributes: [.font: UIFont.preferredFont(forTextStyle: .caption2)]).width + padding
            if width + w + spacing > maxWidth { rows.append([item]); width = w }
            else { if rows.last?.isEmpty ?? true { rows[rows.count-1] = [item] } else { rows[rows.count-1].append(item) }; width += w + spacing }
        }
        return rows
    }
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
