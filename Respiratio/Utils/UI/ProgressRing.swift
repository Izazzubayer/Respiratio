//
//  ProgressRing.swift
//  Respiratio
//
//  Created for Apple-style progress indication
//

import SwiftUI

struct ProgressRing: View {
    let progress: Double
    let isIndeterminate: Bool
    let accent: Color
    
    @State private var spin = false
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            
            if isIndeterminate {
                // Indeterminate spinning animation
                Circle()
                    .trim(from: 0, to: 0.22)
                    .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: spin)
                    .onAppear { spin = true }
                    .onDisappear { spin = false }
            } else {
                // Determinate progress fill
                Circle()
                    .trim(from: 0, to: max(0, min(1, progress)))
                    .stroke(accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Start at 12 o'clock
                    .animation(.linear(duration: 0.2), value: progress)
            }
            
            // Center icon based on state
            Image(systemName: centerIcon)
                .font(.title2.bold())
                .foregroundStyle(.secondary)
        }
    }
    
    private var centerIcon: String {
        if isIndeterminate {
            return "waveform"
        } else if progress >= 1.0 {
            return "checkmark"
        } else {
            return "waveform"
        }
    }
}

// MARK: - Preview
#Preview("Progress Ring - Determinate") {
    VStack(spacing: 32) {
        ProgressRing(progress: 0.0, isIndeterminate: false, accent: .blue)
            .frame(width: 120, height: 120)
        
        ProgressRing(progress: 0.3, isIndeterminate: false, accent: .blue)
            .frame(width: 120, height: 120)
        
        ProgressRing(progress: 0.7, isIndeterminate: false, accent: .blue)
            .frame(width: 120, height: 120)
        
        ProgressRing(progress: 1.0, isIndeterminate: false, accent: .blue)
            .frame(width: 120, height: 120)
    }
    .padding()
}

#Preview("Progress Ring - Indeterminate") {
    ProgressRing(progress: 0, isIndeterminate: true, accent: .blue)
        .frame(width: 120, height: 120)
        .padding()
}
