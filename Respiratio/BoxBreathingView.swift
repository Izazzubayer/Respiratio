//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI
import Foundation
import CoreHaptics
import UIKit

struct BoxBreathingView: View {
    let phase: BreathPhase.Kind
    let phaseDuration: Int
    let secondsLeft: Int
    let tint: Color
    let isRunning: Bool
    let phaseIndex: Int // 0-3 for the four phases of box breathing
    
    // Single time source for continuous motion
    @State private var startDate: Date = Date()
    @State private var hapticEngine: CHHapticEngine?
    @State private var lastHapticPhase: String = "Inhale"
    
    // 16-second cycle (4s per phase)
    private let cycleDuration: Double = 16.0
    private let phaseDurationSeconds: Double = 4.0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: !isRunning)) { context in
            let elapsed = isRunning ? context.date.timeIntervalSince(startDate) : 0
            let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)
            let currentPhase = getCurrentPhase(t: t)
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let boxSize: CGFloat = size * 0.6
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let ballRadius: CGFloat = 12
                let cornerRadius: CGFloat = 16
                
                // Calculate ball position on rounded square path
                let ballPosition = calculateBallPositionOnSquare(
                    t: t, 
                    center: center, 
                    boxSize: boxSize, 
                    cornerRadius: cornerRadius
                )
                
                ZStack {
                    // Background
                    Color(red: 0.21, green: 0.35, blue: 0.97)
                        .ignoresSafeArea()
                    
                    // Progress path around box (no background)
                    ProgressBoxPath(
                        boxSize: boxSize,
                        cornerRadius: cornerRadius,
                        progress: t / cycleDuration
                    )
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    
                    // Moving ball
                    Circle()
                        .fill(tint)
                        .frame(width: ballRadius * 2, height: ballRadius * 2)
                        .position(ballPosition)
                        .shadow(color: tint.opacity(0.6), radius: 8)
                    
                    // Center labels
                    VStack(spacing: 12) {
                        Text(currentPhase.uppercased())
                            .font(.title.weight(.bold))
                            .foregroundStyle(tint)
                        
                        Text(getPhaseDescription(currentPhase, t: t))
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                }
                .onChange(of: currentPhase) { _, newPhase in
                    if isRunning && newPhase != lastHapticPhase {
                        triggerHapticForPhase(newPhase)
                    }
                }
            }
            .onChange(of: isRunning) { _, running in
                if running {
                    startDate = context.date
                } else {
                    hapticEngine?.stop(completionHandler: nil)
                }
            }
        }
        .onAppear {
            setupHapticEngine()
            startDate = Date()
        }
        .onDisappear {
            hapticEngine?.stop(completionHandler: nil)
        }
        .accessibilityLabel(accessibilityText)
    }
    
    // MARK: - Helper Methods
    
    /// Calculate ball position on rounded square path
    private func calculateBallPositionOnSquare(t: Double, center: CGPoint, boxSize: CGFloat, cornerRadius: CGFloat) -> CGPoint {
        let halfSize = boxSize / 2
        let adjustedSize = boxSize - cornerRadius * 2
        let perimeter = adjustedSize * 4 + CGFloat.pi * cornerRadius * 2
        let distance = CGFloat(t / cycleDuration) * perimeter
        
        let straightEdge = adjustedSize
        let quarterCircle = CGFloat.pi * cornerRadius / 2
        
        var currentDistance = distance
        
        // Top edge (0-4s: Inhale - moving right)
        if currentDistance <= straightEdge {
            let progress = currentDistance / straightEdge
            return CGPoint(
                x: center.x - halfSize + cornerRadius + progress * adjustedSize,
                y: center.y - halfSize
            )
        }
        currentDistance -= straightEdge
        
        // Top-right corner (end of inhale)
        if currentDistance <= quarterCircle {
            let angle = (currentDistance / quarterCircle) * CGFloat.pi / 2
            return CGPoint(
                x: center.x + halfSize - cornerRadius + cos(CGFloat.pi / 2 - angle) * cornerRadius,
                y: center.y - halfSize + cornerRadius - cos(angle) * cornerRadius
            )
        }
        currentDistance -= quarterCircle
        
        // Right edge (4-8s: Hold - moving down)
        if currentDistance <= straightEdge {
            let progress = currentDistance / straightEdge
            return CGPoint(
                x: center.x + halfSize,
                y: center.y - halfSize + cornerRadius + progress * adjustedSize
            )
        }
        currentDistance -= straightEdge
        
        // Bottom-right corner (end of first hold)
        if currentDistance <= quarterCircle {
            let angle = (currentDistance / quarterCircle) * CGFloat.pi / 2
            return CGPoint(
                x: center.x + halfSize - cornerRadius + cos(angle) * cornerRadius,
                y: center.y + halfSize - cornerRadius + cos(CGFloat.pi / 2 - angle) * cornerRadius
            )
        }
        currentDistance -= quarterCircle
        
        // Bottom edge (8-12s: Exhale - moving left)
        if currentDistance <= straightEdge {
            let progress = currentDistance / straightEdge
            return CGPoint(
                x: center.x + halfSize - cornerRadius - progress * adjustedSize,
                y: center.y + halfSize
            )
        }
        currentDistance -= straightEdge
        
        // Bottom-left corner (end of exhale)
        if currentDistance <= quarterCircle {
            let angle = (currentDistance / quarterCircle) * CGFloat.pi / 2
            return CGPoint(
                x: center.x - halfSize + cornerRadius - cos(CGFloat.pi / 2 - angle) * cornerRadius,
                y: center.y + halfSize - cornerRadius + cos(angle) * cornerRadius
            )
        }
        currentDistance -= quarterCircle
        
        // Left edge (12-16s: Hold - moving up)
        if currentDistance <= straightEdge {
            let progress = currentDistance / straightEdge
            return CGPoint(
                x: center.x - halfSize,
                y: center.y + halfSize - cornerRadius - progress * adjustedSize
            )
        }
        currentDistance -= straightEdge
        
        // Top-left corner (final hold)
        let angle = (currentDistance / quarterCircle) * CGFloat.pi / 2
        return CGPoint(
            x: center.x - halfSize + cornerRadius - cos(angle) * cornerRadius,
            y: center.y - halfSize + cornerRadius - cos(CGFloat.pi / 2 - angle) * cornerRadius
        )
    }
    
    /// Get current phase based on time position in 16s cycle
    private func getCurrentPhase(t: Double) -> String {
        switch t {
        case 0..<4: return "Inhale"
        case 4..<8: return "Hold"
        case 8..<12: return "Exhale"
        case 12..<16: return "Hold"
        default: return "Inhale"
        }
    }
    
    /// Get phase description for the new UI
    private func getPhaseDescription(_ phase: String, t: Double) -> String {
        switch phase {
        case "Inhale": return "Breathe In Slowly"
        case "Exhale": return "Breathe Out Slowly"
        case "Hold": return getCurrentHoldDescription(t: t)
        default: return "Follow the square"
        }
    }
    
    /// Get specific hold description based on position in cycle
    private func getCurrentHoldDescription(t: Double) -> String {
        switch t {
        case 4..<8: return "Hold Your Breath"
        case 12..<16: return "Hold Empty Lungs"
        default: return "Hold"
        }
    }
    
    /// Accessibility text
    private var accessibilityText: String {
        "Box breathing exercise. Follow the breathing phases with visual guidance. Current phase indicates breathing instruction."
    }
    
    // MARK: - Haptic Methods
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            hapticEngine?.playsHapticsOnly = true
        } catch {
            print("Failed to setup haptic engine:", error)
            hapticEngine = nil
        }
    }
    
    private func triggerHapticForPhase(_ phase: String) {
        print("🎯 Triggering haptic for phase: \(phase)")
        
        DispatchQueue.main.async {
            self.lastHapticPhase = phase
        }
        
        guard let engine = hapticEngine else {
            print("⚠️ No haptic engine, falling back to UIKit haptics")
            triggerUIKitHaptic(for: phase)
            return
        }
        
        do {
            let pattern = try createHapticPattern(for: phase)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            print("✅ Haptic pattern played successfully for \(phase)")
        } catch {
            print("❌ Failed to play haptic pattern for \(phase): \(error)")
            triggerUIKitHaptic(for: phase)
        }
    }
    
    private func triggerUIKitHaptic(for phase: String) {
        print("🔨 Using UIKit haptic for \(phase)")
        
        switch phase {
        case "Inhale":
            // Double tap for inhale - building energy
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                generator.impactOccurred(intensity: 0.8)
            }
        case "Hold":
            // Single strong tap for hold
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
        case "Exhale":
            // Triple descending taps for exhale - releasing energy
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                generator.impactOccurred(intensity: 0.7)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                generator.impactOccurred(intensity: 0.4)
            }
        default:
            break
        }
    }
    
    private func createHapticPattern(for phase: String) throws -> CHHapticPattern {
        switch phase {
        case "Inhale":
            return try createInhalePattern()
        case "Hold":
            return try createHoldPattern()
        case "Exhale":
            return try createExhalePattern()
        default:
            return try createInhalePattern()
        }
    }
    
    private func createInhalePattern() throws -> CHHapticPattern {
        // Powerful building energy pattern for inhale - starts with impact, then continuous ramp
        var events: [CHHapticEvent] = []
        
        // Initial strong impact to signal start of inhale
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        ))
        
        // Continuous building energy throughout the inhale
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ],
            relativeTime: 0.1,
            duration: 3.9
        ))
        
        // Subtle pulsing to maintain engagement
        for i in stride(from: 0.5, through: 3.5, by: 0.5) {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: i
            ))
        }
        
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.4),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 2.0, value: 0.7),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4.0, value: 0.9)
                ],
                relativeTime: 0.1
            ),
            CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.3),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4.0, value: 0.6)
                ],
                relativeTime: 0.1
            )
        ]
        
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
    
    private func createHoldPattern() throws -> CHHapticPattern {
        // Strong, rhythmic pulses for hold phase - maintaining energy
        var events: [CHHapticEvent] = []
        
        // Initial strong pulse to signal hold start
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0
        ))
        
        // Sustained energy with powerful rhythmic pulses
        let pulseInterval: TimeInterval = 0.8
        for i in 1..<5 {
            let pulse = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: TimeInterval(i) * pulseInterval
            )
            events.append(pulse)
        }
        
        // Subtle continuous vibration to maintain tension
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ],
            relativeTime: 0.2,
            duration: 3.6
        ))
        
        return try CHHapticPattern(events: events, parameterCurves: [])
    }
    
    private func createExhalePattern() throws -> CHHapticPattern {
        // Powerful releasing pattern for exhale - starts strong, gradually releases
        var events: [CHHapticEvent] = []
        
        // Strong initial burst to signal exhale start
        events.append(CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 0
        ))
        
        // Continuous decreasing energy throughout exhale
        events.append(CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.1,
            duration: 3.9
        ))
        
        // Descending pulses for gradual release feeling
        let pulseTimes: [TimeInterval] = [0.8, 1.6, 2.4, 3.2]
        let intensities: [Float] = [0.8, 0.6, 0.4, 0.2]
        
        for (time, intensity) in zip(pulseTimes, intensities) {
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: time
            ))
        }
        
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.9),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 2.0, value: 0.5),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4.0, value: 0.1)
                ],
                relativeTime: 0.1
            ),
            CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0.1, value: 0.6),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4.0, value: 0.2)
                ],
                relativeTime: 0.1
            )
        ]
        
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
}

// MARK: - Progress Box Path Shape

struct ProgressBoxPath: Shape {
    let boxSize: CGFloat
    let cornerRadius: CGFloat
    let progress: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfSize = boxSize / 2
        let adjustedSize = boxSize - cornerRadius * 2
        let perimeter = adjustedSize * 4 + CGFloat.pi * cornerRadius * 2
        let distance = CGFloat(progress) * perimeter
        
        let straightEdge = adjustedSize
        let quarterCircle = CGFloat.pi * cornerRadius / 2
        
        var path = Path()
        var currentDistance: CGFloat = 0
        
        // Start point (top-left after corner)
        let startPoint = CGPoint(
            x: center.x - halfSize + cornerRadius,
            y: center.y - halfSize
        )
        path.move(to: startPoint)
        
        // Top edge
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, straightEdge)
            path.addLine(to: CGPoint(
                x: startPoint.x + segmentLength,
                y: startPoint.y
            ))
            if distance <= currentDistance + straightEdge { return path }
        }
        currentDistance += straightEdge
        
        // Top-right corner
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, quarterCircle)
            let endAngle = (segmentLength / quarterCircle) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: center.x + halfSize - cornerRadius, y: center.y - halfSize + cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: -Double.pi / 2),
                endAngle: Angle(radians: -Double.pi / 2 + Double(endAngle)),
                clockwise: false
            )
            if distance <= currentDistance + quarterCircle { return path }
        }
        currentDistance += quarterCircle
        
        // Right edge
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, straightEdge)
            path.addLine(to: CGPoint(
                x: center.x + halfSize,
                y: center.y - halfSize + cornerRadius + segmentLength
            ))
            if distance <= currentDistance + straightEdge { return path }
        }
        currentDistance += straightEdge
        
        // Bottom-right corner
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, quarterCircle)
            let endAngle = (segmentLength / quarterCircle) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: center.x + halfSize - cornerRadius, y: center.y + halfSize - cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: 0),
                endAngle: Angle(radians: Double(endAngle)),
                clockwise: false
            )
            if distance <= currentDistance + quarterCircle { return path }
        }
        currentDistance += quarterCircle
        
        // Bottom edge
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, straightEdge)
            path.addLine(to: CGPoint(
                x: center.x + halfSize - cornerRadius - segmentLength,
                y: center.y + halfSize
            ))
            if distance <= currentDistance + straightEdge { return path }
        }
        currentDistance += straightEdge
        
        // Bottom-left corner
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, quarterCircle)
            let endAngle = (segmentLength / quarterCircle) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: center.x - halfSize + cornerRadius, y: center.y + halfSize - cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: Double.pi / 2),
                endAngle: Angle(radians: Double.pi / 2 + Double(endAngle)),
                clockwise: false
            )
            if distance <= currentDistance + quarterCircle { return path }
        }
        currentDistance += quarterCircle
        
        // Left edge
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, straightEdge)
            path.addLine(to: CGPoint(
                x: center.x - halfSize,
                y: center.y + halfSize - cornerRadius - segmentLength
            ))
            if distance <= currentDistance + straightEdge { return path }
        }
        currentDistance += straightEdge
        
        // Top-left corner
        if distance > currentDistance {
            let segmentLength = min(distance - currentDistance, quarterCircle)
            let endAngle = (segmentLength / quarterCircle) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: center.x - halfSize + cornerRadius, y: center.y - halfSize + cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: Double.pi),
                endAngle: Angle(radians: Double.pi + Double(endAngle)),
                clockwise: false
            )
        }
        
        return path
    }
}

#Preview {
    BoxBreathingView(
        phase: .inhale,
        phaseDuration: 4,
        secondsLeft: 3,
        tint: .blue,
        isRunning: true,
        phaseIndex: 0
    )
    .frame(width: 300, height: 300)
    .padding()
}
