//
//  BoxBreathingView.swift
//  Respiratio
//
//  Visual breathing animation for box breathing technique
//  Session controls are handled by parent BreathingSessionView
//

import SwiftUI
import CoreHaptics

struct BoxBreathingView: View {
    @State private var isAnimating = false
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var phaseTimer: Timer?
    
    // Simple, reliable haptic system
    private let inhaleHaptic = UIImpactFeedbackGenerator(style: .light)
    private let holdHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let exhaleHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    enum BreathingPhase: String, CaseIterable {
        case inhale = "Inhale"
        case hold1 = "Hold In"
        case exhale = "Exhale"
        case hold2 = "Hold Out"
        
        var duration: TimeInterval {
            switch self {
            case .inhale: return 4.0
            case .hold1: return 4.0
            case .exhale: return 4.0
            case .hold2: return 4.0
            }
        }
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe in slowly"
            case .hold1: return "Hold your breath"
            case .exhale: return "Breathe out slowly"
            case .hold2: return "Hold empty"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Breathing Box Outline with design system colors
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xlarge)
                .stroke(DesignSystem.Colors.primary, lineWidth: 3)
                .frame(width: 280, height: 280)
                .shadowMedium()
            
            // Phase Text in Center with design system typography
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(breathingPhase.rawValue.uppercased())
                    .font(DesignSystem.Typography.title2.weight(.bold))
                    .foregroundColor(DesignSystem.Colors.primaryText)
                
                Text(breathingPhase.instruction)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(width: 280, height: 280)
        .onAppear {
            startBreathingAnimation()
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }
    
    // MARK: - Animation Control
    
    private func startBreathingAnimation() {
        isAnimating = true
        startPhaseTimer()
    }
    
    private func stopBreathingAnimation() {
        isAnimating = false
        phaseTimer?.invalidate()
        phaseTimer = nil
    }
    
    private func startPhaseTimer() {
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            advancePhase()
        }
    }
    
    private func advancePhase() {
        let currentIndex = BreathingPhase.allCases.firstIndex(of: breathingPhase) ?? 0
        let nextIndex = (currentIndex + 1) % BreathingPhase.allCases.count
        breathingPhase = BreathingPhase.allCases[nextIndex]
        
        // Provide haptic feedback for phase changes
        switch breathingPhase {
        case .inhale:
            inhaleHaptic.impactOccurred()
        case .hold1, .hold2:
            holdHaptic.impactOccurred()
        case .exhale:
            exhaleHaptic.impactOccurred()
        }
    }
}

#Preview {
    BoxBreathingView()
        .background(DesignSystem.Colors.background)
}
