//
//  BreathingView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-20.
//

import SwiftUI

struct BreathingView: View {
    private let items = BreathingExercise.all
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { ex in
                        NavigationLink {
                            BreathingSessionView(exercise: ex, totalSeconds: 120) // 2 minutes
                        } label: {
                            Row(exercise: ex)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Breathing")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private struct Row: View {
        let exercise: BreathingExercise
        var body: some View {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(exercise.tint.opacity(0.18))
                    Image(systemName: exercise.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(exercise.tint)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(exercise.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Fixed duration badge
                Text("2 min")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.blue)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Capsule().fill(Color.blue.opacity(0.15)))
                    .allowsHitTesting(false)
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
    }
}

#Preview { BreathingView() }
