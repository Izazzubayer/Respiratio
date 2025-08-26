//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI
import DotLottie
import CoreHaptics

struct BoxBreathingView: View {
    @State private var isAnimating = false
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var phaseTimer: Timer?
    @State private var hapticEngine: CHHapticEngine?
    
    // Lottie animation reference
    @State private var breathingAnimation: DotLottieAnimation?
    
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
    }

    var body: some View {
        ZStack() {
            VStack(alignment: .leading, spacing: 15) {
                HStack(spacing: 4) {
                    Text("2 Minutes")
                        .font(Font.custom("Anek Gujarati", size: 12).weight(.medium))
                        .foregroundColor(.white)
                }
                .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                .background(Color(red: 0.36, green: 0.47, blue: 1))
                .cornerRadius(999)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Box Breathing")
                        .font(Font.custom("Amagro", size: 24).weight(.bold))
                        .lineSpacing(26)
                        .foregroundColor(.white)
                    Text("Inhale, hold, exhale, and hold again. Repeat this for 2 minutes to calm the mind & sharpen focus.")
                        .font(Font.custom("Anek Gujarati", size: 18))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 376)
            .offset(x: 0, y: -300)

            // Lottie Animation Area
            VStack(spacing: 16) {
                if let breathingAnimation = breathingAnimation {
                    breathingAnimation.view()
                        .frame(width: 280, height: 280)
                }
            }

            HStack(spacing: 18) {
                Button(action: {
                    if isAnimating {
                        pauseBreathingAnimation()
                    } else {
                        startBreathingAnimation()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isAnimating ? "Pause" : "Play")
                            .font(Font.custom("Anek Gujarati", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(EdgeInsets(top: 12, leading: 48, bottom: 12, trailing: 48))
                    .background(Color(red: 0.17, green: 0.28, blue: 0.79))
                    .cornerRadius(12)
                }

                Button(action: {
                    stopBreathingAnimation()
                }) {
                    HStack(spacing: 4) {
                        Text("Stop")
                            .font(Font.custom("Anek Gujarati", size: 16))
                            .foregroundColor(.white)
                    }
                    .padding(EdgeInsets(top: 12, leading: 48, bottom: 12, trailing: 48))
                    .background(Color(red: 0.84, green: 0.36, blue: 0.28))
                    .cornerRadius(12)
                }
            }
            .offset(x: 0, y: 264)
        }
        .frame(width: 430, height: 932)
        .background(Color(red: 0.10, green: 0.17, blue: 0.48))
        .onAppear {
            setupLottieAnimation()
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }

    // MARK: - Lottie Animation Setup
    
    private func setupLottieAnimation() {
        // Load Lottie animation from local file
        breathingAnimation = DotLottieAnimation(
            fileName: "Box Breathing V6",
            config: AnimationConfig(autoplay: false, loop: true)
        )
        
        // Setup haptic engine
        setupHapticEngine()
    }
    
    // MARK: - Haptic Engine Setup
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device doesn't support Core Haptics")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            print("Haptic engine setup successfully")
        } catch {
            print("Failed to setup haptic engine: \(error.localizedDescription)")
        }
    }

    // MARK: - Breathing Animation Logic
    
    private func startBreathingAnimation() {
        isAnimating = true
        breathingPhase = .inhale
        
        // Start session timer for 2 minutes
        sessionTime = 0.0
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sessionTime += 1.0
            if sessionTime >= 120.0 { // 2 minutes
                stopBreathingAnimation()
                return
            }
        }
        
        // Start breathing phase timer with haptic feedback
        startBreathingPhaseTimer()
        
        // Start the Lottie animation
        if let breathingAnimation = breathingAnimation {
            breathingAnimation.play()
        }
    }
    
    private func startBreathingPhaseTimer() {
        var phaseStartTime = Date()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in // 20 FPS for reliable haptics
            let elapsed = Date().timeIntervalSince(phaseStartTime)
            let currentPhase = self.getCurrentPhase(elapsed: elapsed)
            
            if currentPhase != self.breathingPhase {
                self.breathingPhase = currentPhase
                phaseStartTime = Date()
            }
            
            // Continuous haptic feedback during each phase
            self.updateHapticFeedback(elapsed: elapsed, phase: self.breathingPhase)
        }
    }
    
    private func updateHapticFeedback(elapsed: TimeInterval, phase: BreathingPhase) {
        let phaseElapsed = elapsed.truncatingRemainder(dividingBy: 4.0)
        let phaseProgress = phaseElapsed / 4.0
        
        switch phase {
        case .inhale:
            // Continuous vibration: 0% to 50% strength
            let intensity = phaseProgress * 0.5 // 0.0 to 0.5
            triggerContinuousHaptic(intensity: intensity, style: .light)
            
        case .hold1, .hold2:
            // 100% strength heartbeat thuds every 0.3 seconds
            if Int(phaseElapsed * 3.33) % 1 == 0 { // Every 0.3 seconds
                holdHaptic.prepare()
                holdHaptic.impactOccurred()
            }
            
        case .exhale:
            // Continuous vibration: 50% to 0% strength
            let intensity = (1.0 - phaseProgress) * 0.5 // 0.5 to 0.0
            triggerContinuousHaptic(intensity: intensity, style: .medium)
        }
    }
    
    private func triggerContinuousHaptic(intensity: Double, style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Create continuous haptic feedback
        let haptic = UIImpactFeedbackGenerator(style: style)
        haptic.prepare()
        
        // Apply intensity by adjusting the impact
        if intensity > 0.3 {
            haptic.impactOccurred(intensity: CGFloat(intensity))
        } else {
            haptic.impactOccurred()
        }
    }
    
    private func getCurrentPhase(elapsed: TimeInterval) -> BreathingPhase {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        
        let cycleTime = elapsed.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleTime < 4.0 {
            return .inhale
        } else if cycleTime < 8.0 {
            return .hold1
        } else if cycleTime < 12.0 {
            return .exhale
        } else {
            return .hold2
        }
    }

    private func pauseBreathingAnimation() {
        isAnimating = false
        
        // Pause the Lottie animation
        if let breathingAnimation = breathingAnimation {
            breathingAnimation.pause()
        }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        phaseTimer?.invalidate()
        phaseTimer = nil
        
        // Stop haptic feedback
        hapticEngine?.stop()
    }

    private func stopBreathingAnimation() {
        isAnimating = false
        
        // Stop the Lottie animation
        if let breathingAnimation = breathingAnimation {
            breathingAnimation.stop()
        }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        phaseTimer?.invalidate()
        phaseTimer = nil
        
        // Reset breathing phase
        breathingPhase = .inhale
        
        // Stop haptic feedback
        hapticEngine?.stop()

        withAnimation(.easeInOut(duration: 0.3)) {
            sessionTime = 0.0
        }
    }

    // MARK: - Helper Functions
    
    private func getPhaseProgress() -> Double {
        let totalDuration = 16.0 // Total cycle time
        let currentPhaseIndex = BreathingPhase.allCases.firstIndex(of: breathingPhase) ?? 0
        let phaseStartTime = Double(currentPhaseIndex) * 4.0
        let phaseElapsed = sessionTime - phaseStartTime
        return max(0, min(1, phaseElapsed / 4.0))
    }
}

// MARK: - Preview

#Preview("Box Breathing View") {
    BoxBreathingView()
}

#Preview("Box Breathing View - Dark") {
    BoxBreathingView()
        .preferredColorScheme(.dark)
}
