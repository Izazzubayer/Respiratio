//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI
import CoreHaptics
// import DotLottie  // Temporarily commented out until package is properly linked

struct BoxBreathingView: View {
    @State private var isAnimating = false
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var phaseTimer: Timer?
    @State private var hapticEngine: CHHapticEngine?
    @State private var breathingAnimation: Any?  // Temporarily commented out DotLottieAnimation
    
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
            // Custom Back Button with reduced opacity
            VStack {
                HStack {
                    Button(action: {
                        // This will trigger the back navigation
                        // The actual navigation is handled by the parent view
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(Font.custom("Anek Gujarati", size: 16))
                        }
                        .foregroundColor(.white)
                        .opacity(0.0) // Completely invisible but still functional
                    }
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                }
                Spacer()
            }
            
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
            .offset(x: 0, y: -250)

                         // Lottie Animation Area
             VStack(spacing: 16) {
                 ZStack {
                     // Breathing Box Outline
                     RoundedRectangle(cornerRadius: 20)
                         .stroke(Color.teal, lineWidth: 3)
                         .frame(width: 280, height: 280)
                     
                     // Lottie Animation
                     // if let breathingAnimation = breathingAnimation {
                     //     breathingAnimation
                     //         .view()
                     //         .frame(width: 280, height: 280)
                     // } else {
                         // Fallback if Lottie fails to load
                         Text("Breathing Animation")
                             .foregroundColor(.white)
                             .frame(width: 280, height: 280)
                     // }
                     
                     // Phase Text in Center
                     VStack(spacing: 8) {
                         Text(getCurrentPhaseName().uppercased())
                            .font(Font.custom("Amagro", size: 24).weight(.bold))
                            .foregroundColor(.white)
                         
                         Text(getPhaseInstruction())
                              .font(Font.custom("Anek Gujarati", size: 16))
                              .foregroundColor(.white.opacity(0.8))
                     }
                 }
                 .frame(width: 280, height: 280)
                
                // Debug Screen
                // VStack(spacing: 8) {
                //     Text("DEBUG INFO")
                //         .font(Font.custom("Anek Gujarati", size: 14).weight(.bold))
                //         .foregroundColor(.yellow)
                    
                //     VStack(spacing: 4) {
                //         HStack {
                //             Text("Phase:")
                //             Text(getCurrentPhaseName())
                //                 .foregroundColor(.white)
                //         }
                //         .font(Font.custom("Anek Gujarati", size: 12))
                        
                //         HStack {
                //             Text("Session Time:")
                //             Text("\(Int(sessionTime))s")
                //         .foregroundColor(.white)
                //         }
                //         .font(Font.custom("Anek Gujarati", size: 12))
                    
                //         HStack {
                //             Text("Cycle Time:")
                //             Text(String(format: "%.1fs", getCurrentCycleTime()))
                //         .foregroundColor(.white)
                //         }
                //         .font(Font.custom("Anek Gujarati", size: 12))
                        
                //         HStack {
                //             Text("Intensity:")
                //             Text(String(format: "%.1f%%", getCurrentIntensity() * 100))
                //                 .foregroundColor(.green)
                //         }
                //         .font(Font.custom("Anek Gujarati", size: 12))
                //     }
                //     .padding(8)
                //     .background(Color.black.opacity(0.2))
                //     .cornerRadius(8)
                // }
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
            setupHapticEngine()
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }

    // MARK: - Lottie Animation Setup
    
    private func setupLottieAnimation() {
        print("Setting up Lottie animation...")
        // breathingAnimation = DotLottieAnimation(fileName: "Box Breathing V6", config: AnimationConfig())  // Temporarily commented out
        if breathingAnimation != nil {
            print("Lottie animation loaded successfully!")
        } else {
            print("Failed to load Lottie animation")
        }
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
        // Note: DotLottieAnimation doesn't have play/pause/stop methods
        // The animation will play automatically when displayed
    }
    
    private func startBreathingPhaseTimer() {
        var phaseStartTime = Date()
        
        phaseTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in // 10 FPS for reliable haptics
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
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime) // Use sessionTime instead of elapsed
        
        if cycleTime < 4.0 {
            // Inhale: haptic vibration gradually increase from 0% to 80%
            let phaseProgress = cycleTime / 4.0
            let intensity = phaseProgress * 0.8 // 0.0 to 0.8
            if Int(cycleTime * 10) % 2 == 0 { // Every 0.2 seconds
                triggerProgressiveHaptic(intensity: intensity, style: .light)
            }
            
        } else if cycleTime < 8.0 {
            // Hold1: completely silent - no haptic feedback
            // No background vibration, no thuds - complete silence
            
        } else if cycleTime < 12.0 {
            // Exhale: haptic vibration gradually decrease from 40% to 0
            let phaseProgress = (cycleTime - 8.0) / 4.0
            let intensity = (1.0 - phaseProgress) * 0.4 // 0.4 to 0.0
            if Int((cycleTime - 8.0) * 10) % 2 == 0 { // Every 0.2 seconds
                triggerProgressiveHaptic(intensity: intensity, style: .medium)
            }
            
        } else {
            // Hold2: completely silent - no haptic feedback
            // No background vibration, no thuds - complete silence
        }
    }
    
    private func triggerProgressiveHaptic(intensity: Double, style: UIImpactFeedbackGenerator.FeedbackStyle) {
        // Create haptic with progressive intensity
        let haptic = UIImpactFeedbackGenerator(style: style)
        haptic.prepare()
        
        // Debug output to see intensity values
        print("Haptic Intensity: \(intensity), Style: \(style)")
        
        // Use different haptic styles based on intensity
        if intensity > 0.6 {
            let strongHaptic = UIImpactFeedbackGenerator(style: .heavy)
            strongHaptic.prepare()
            strongHaptic.impactOccurred()
        } else if intensity > 0.3 {
            let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
            mediumHaptic.prepare()
            mediumHaptic.impactOccurred()
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
    
    private func getCurrentCycleTime() -> Double {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime)
        return cycleTime
    }
    
    private func getCurrentIntensity() -> Double {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleTime < 4.0 {
            // Inhale: smooth progression from 0% to 80%
            let phaseProgress = cycleTime / 4.0
            return phaseProgress * 0.8 // 0.0 to 0.8
        } else if cycleTime < 8.0 {
            return 0.0 // No intensity during hold1 (silent)
        } else if cycleTime < 12.0 {
            // Exhale: smooth progression from 40% to 0%
            let phaseProgress = (cycleTime - 8.0) / 4.0
            return (1.0 - phaseProgress) * 0.4 // 0.4 to 0.0
        } else {
            return 0.0 // No intensity during hold2 (silent)
        }
    }

    private func pauseBreathingAnimation() {
        isAnimating = false
        
        // Pause the Lottie animation
        // Note: DotLottieAnimation doesn't have play/pause/stop methods
        // The animation will pause when the view is not visible
        
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
        // Note: DotLottieAnimation doesn't have play/pause/stop methods
        // The animation will stop when the view is removed
        
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

    private func getCurrentPhaseName() -> String {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleTime < 4.0 {
            return BreathingPhase.inhale.rawValue
        } else if cycleTime < 8.0 {
            return BreathingPhase.hold1.rawValue
        } else if cycleTime < 12.0 {
            return BreathingPhase.exhale.rawValue
        } else {
            return BreathingPhase.hold2.rawValue
        }
    }

    private func getPhaseInstruction() -> String {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime)
        
        if cycleTime < 4.0 {
            return "Inhale"
        } else if cycleTime < 8.0 {
            return "Hold"
        } else if cycleTime < 12.0 {
            return "Exhale"
        } else {
            return "Hold"
        }
    }

    private func getBreathingCircleOffset() -> CGSize {
        let totalCycleTime: TimeInterval = 16.0 // 4 seconds per phase
        let cycleTime = sessionTime.truncatingRemainder(dividingBy: totalCycleTime)
        
        let boxSize: CGFloat = 280
        let halfBox = boxSize / 2
        let circleSize: CGFloat = 20
        let offsetRange = halfBox - (circleSize / 2)
        
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        if cycleTime < 4.0 { // Inhale (Bottom-Right to Top-Right)
            let progress = cycleTime / 4.0
            x = offsetRange
            y = offsetRange - (progress * 2 * offsetRange)
        } else if cycleTime < 8.0 { // Hold In (Top-Right to Top-Left)
            let progress = (cycleTime - 4.0) / 4.0
            x = offsetRange - (progress * 2 * offsetRange)
            y = -offsetRange
        } else if cycleTime < 12.0 { // Exhale (Top-Left to Bottom-Left)
            let progress = (cycleTime - 8.0) / 4.0
            x = -offsetRange
            y = -offsetRange + (progress * 2 * offsetRange)
        } else { // Hold Out (Bottom-Left to Bottom-Right)
            let progress = (cycleTime - 12.0) / 4.0
            x = -offsetRange + (progress * 2 * offsetRange)
            y = offsetRange
        }
        
        return CGSize(width: x, height: y)
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
