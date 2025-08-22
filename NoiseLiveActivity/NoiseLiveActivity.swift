//
//  NoiseLiveActivity.swift
//  NoiseLiveActivity
//
//  Created by Izzy Drizzy on 2025-08-22.
//// FILE: NoiseLiveActivity.swift  (TARGET: NoiseLiveActivity extension)
import ActivityKit
import WidgetKit
import SwiftUI

struct NoiseIslandView: View {
    let context: ActivityViewContext<NoiseActivityAttributes>

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: context.state.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.title).font(.headline)
                if let remaining = context.state.remainingSeconds {
                    Text(timeString(remaining)).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60, s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct NoiseLockView: View {
    let context: ActivityViewContext<NoiseActivityAttributes>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.state.title).font(.headline)
            if let remaining = context.state.remainingSeconds {
                ProgressView(value: Double(remaining),
                             total: Double(max(remaining, 1)))
                    .tint(.blue)
            }
            Text(context.state.isPlaying ? "Playing" : "Paused")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct NoiseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: NoiseActivityAttributes.self) { context in
            NoiseLockView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    NoiseIslandView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.state.isPlaying ? "speaker.wave.2.fill" : "speaker.slash.fill")
            } compactTrailing: {
                if let r = context.state.remainingSeconds {
                    Text("\(r/60)m").monospacedDigit()
                }
            } minimal: {
                Image(systemName: context.state.isPlaying ? "waveform" : "pause.fill")
            }
        }
    }
}
