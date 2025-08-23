//
//  TriangleBreathingView.swift
//  Respiratio
//
//  4-7-8 Breathing Triangle Visualization
//  Right-angle triangle with sides proportional to breathing phases
//

import SwiftUI
import CoreHaptics
import UIKit

struct TriangleBreathingView: View {
    let phase: BreathPhase.Kind
    let phaseDuration: Int
    let secondsLeft: Int
    let tint: Color
    let isRunning: Bool
    let phaseIndex: Int
    
    // 4-7-8 breathing pattern: Inhale(4) -> Hold(7) -> Exhale(8)
    private let cycleDuration: Double = 19.0 // 4 + 7 + 8 seconds
    private let inhaleSeconds: Double = 4.0
    private let holdSeconds: Double = 7.0
    private let exhaleSeconds: Double = 8.0
    
    @State private var startDate: Date = Date()
    @State private var hapticEngine: CHHapticEngine?
    @State private var lastHapticPhase: String = ""
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: !isRunning)) { context in
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let triangleSize: CGFloat = size * 0.95
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let ballRadius: CGFloat = 12
                
                // Calculate elapsed time and position on triangle
                let elapsed = isRunning ? context.date.timeIntervalSince(startDate) : 0
                let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)
                
                // Calculate ball position on triangle perimeter
                let ballPosition = calculateBallPositionOnTriangle(t: t, center: center, size: triangleSize)
                
                // Determine current phase and remaining time
                let currentPhase = getCurrentPhase(t: t)
                let secondsLeftInPhase = getSecondsLeftInPhase(t: t)
                
                // Haptic triggering handled in onChange modifier below
                
                ZStack {
                    // Background triangle outline
                    TrianglePath(size: triangleSize)
                        .stroke(tint.opacity(0.3), lineWidth: 8)
                    
                    // Progress path around triangle (synchronized with ball)
                    TriangleProgressPath(
                        size: triangleSize,
                        progress: t / cycleDuration
                    )
                    .stroke(tint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    
                    // Moving ball
                    Circle()
                        .fill(tint)
                        .frame(width: ballRadius * 2, height: ballRadius * 2)
                        .position(ballPosition)
                        .shadow(color: tint.opacity(0.6), radius: 8)
                    
                    // Center instruction text
                    Text(currentPhase.uppercased())
                        .font(.title.weight(.bold))
                        .foregroundStyle(tint)
                        .contentTransition(.opacity)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityText(currentPhase, secondsLeftInPhase))
            }
        }
        .onAppear {
            startDate = Date()
            setupHapticEngine()
        }
        .onDisappear {
            hapticEngine?.stop()
        }
        .onChange(of: isRunning) { _, newValue in
            if newValue {
                startDate = Date()
            } else {
                hapticEngine?.stop()
            }
        }
        .onChange(of: phaseIndex) { _, _ in
            // Trigger haptics when phase changes via model
            if isRunning {
                let elapsed = Date().timeIntervalSince(startDate)
                let t = elapsed.truncatingRemainder(dividingBy: cycleDuration)
                let currentPhase = getCurrentPhase(t: t)
                if currentPhase != lastHapticPhase {
                    triggerHapticForPhase(currentPhase)
                }
            }
        }
    }
    
    // MARK: - Triangle Calculations
    
    private func calculateBallPositionOnTriangle(t: Double, center: CGPoint, size: CGFloat) -> CGPoint {
        let cornerRadius: CGFloat = 16
        
        // Create a proper right-angle triangle that fits well on screen
        // Base width and height proportional to breathing phases but visually balanced
        let triangleWidth = size * 0.7   // Bottom edge - inhale (4s)
        let triangleHeight = size * 0.6  // Right edge - hold (7s)
        
        // Position triangle vertices to create right angle at bottom-right
        let bottomLeft = CGPoint(x: center.x - triangleWidth/2, y: center.y + triangleHeight/2)
        let bottomRight = CGPoint(x: center.x + triangleWidth/2, y: center.y + triangleHeight/2)
        let top = CGPoint(x: center.x - triangleWidth/6, y: center.y - triangleHeight/2)
        
        // Calculate perimeter segments (matching TriangleProgressPath)
        let bottomEdge = distance(from: bottomLeft, to: bottomRight) - cornerRadius * 2
        let rightEdge = distance(from: bottomRight, to: top) - cornerRadius * 2  
        let leftEdge = distance(from: top, to: bottomLeft) - cornerRadius * 2
        let cornerLength = CGFloat.pi * cornerRadius / 2
        let totalPerimeter = bottomEdge + rightEdge + leftEdge + cornerLength * 3
        
        let targetDistance = CGFloat(t / cycleDuration) * totalPerimeter
        var currentDistance: CGFloat = 0
        
        // Bottom edge (Inhale - 4 seconds): left to right
        let adjustedBottomLeft = CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y)
        let adjustedBottomRight = CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y)
        
        if targetDistance <= currentDistance + bottomEdge {
            let progress = (targetDistance - currentDistance) / bottomEdge
            return CGPoint(
                x: adjustedBottomLeft.x + progress * (adjustedBottomRight.x - adjustedBottomLeft.x),
                y: adjustedBottomLeft.y
            )
        }
        currentDistance += bottomEdge
        
        // Bottom-right corner
        if targetDistance <= currentDistance + cornerLength {
            let progress = (targetDistance - currentDistance) / cornerLength
            let angle = progress * CGFloat.pi / 2
            return CGPoint(
                x: bottomRight.x - cornerRadius + sin(angle) * cornerRadius,
                y: bottomRight.y - cornerRadius + cos(angle) * cornerRadius
            )
        }
        currentDistance += cornerLength
        
        // Right edge (Hold - 7 seconds): bottom to top
        let adjustedBottomRightEdge = CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius)
        let adjustedTopRight = CGPoint(x: top.x, y: top.y + cornerRadius)
        
        if targetDistance <= currentDistance + rightEdge {
            let progress = (targetDistance - currentDistance) / rightEdge
            return CGPoint(
                x: adjustedBottomRightEdge.x + progress * (adjustedTopRight.x - adjustedBottomRightEdge.x),
                y: adjustedBottomRightEdge.y + progress * (adjustedTopRight.y - adjustedBottomRightEdge.y)
            )
        }
        currentDistance += rightEdge
        
        // Top corner
        if targetDistance <= currentDistance + cornerLength {
            let progress = (targetDistance - currentDistance) / cornerLength
            let angle = progress * CGFloat.pi / 2
            return CGPoint(
                x: top.x - sin(angle) * cornerRadius,
                y: top.y + cos(angle) * cornerRadius
            )
        }
        currentDistance += cornerLength
        
        // Left edge (Exhale - 8 seconds): top to bottom
        let adjustedTopLeft = CGPoint(x: top.x - cornerRadius, y: top.y)
        let adjustedBottomLeftEdge = CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius)
        
        if targetDistance <= currentDistance + leftEdge {
            let progress = (targetDistance - currentDistance) / leftEdge
            return CGPoint(
                x: adjustedTopLeft.x + progress * (adjustedBottomLeftEdge.x - adjustedTopLeft.x),
                y: adjustedTopLeft.y + progress * (adjustedBottomLeftEdge.y - adjustedTopLeft.y)
            )
        }
        currentDistance += leftEdge
        
        // Bottom-left corner
        let progress = (targetDistance - currentDistance) / cornerLength
        let angle = progress * CGFloat.pi / 2
        return CGPoint(
            x: bottomLeft.x + cornerRadius - cos(angle) * cornerRadius,
            y: bottomLeft.y - cornerRadius + sin(angle) * cornerRadius
        )
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    

    
    private func getCurrentPhase(t: Double) -> String {
        if t <= inhaleSeconds {
            return "Inhale"
        } else if t <= inhaleSeconds + holdSeconds {
            return "Hold"
        } else {
            return "Exhale"
        }
    }
    
    private func getSecondsLeftInPhase(t: Double) -> Int {
        if t <= inhaleSeconds {
            return Int(ceil(inhaleSeconds - t))
        } else if t <= inhaleSeconds + holdSeconds {
            return Int(ceil((inhaleSeconds + holdSeconds) - t))
        } else {
            return Int(ceil(cycleDuration - t))
        }
    }
    
    private func getPhaseDescription(_ phase: String, t: Double) -> String {
        switch phase {
        case "Hold":
            return "HOLD"
        case "Exhale":
            return "EXHALE"
        default:
            return "INHALE"
        }
    }
    
    private func accessibilityText(_ phase: String, _ secondsLeft: Int) -> String {
        return "\(phase) for \(secondsLeft) seconds"
    }
    
    // MARK: - Haptic Feedback
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    private func triggerHapticForPhase(_ phase: String) {
        print("🎯 Triggering haptic for 4-7-8 phase: \(phase)")
        
        DispatchQueue.main.async {
            self.lastHapticPhase = phase
        }
        
        guard let engine = hapticEngine else {
            triggerUIKitHaptic(for: phase)
            return
        }
        
        do {
            let pattern = try createHapticPattern(for: phase)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
            triggerUIKitHaptic(for: phase)
        }
    }
    
    private func triggerUIKitHaptic(for phase: String) {
        print("🔨 Using UIKit haptic for 4-7-8 \(phase)")
        
        switch phase {
        case "Inhale":
            // Light building energy for inhale (4 seconds)
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred(intensity: 0.8)
        case "Hold":
            // Strong sustained for hold (7 seconds)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred(intensity: 1.0)
        case "Exhale":
            // Gentle release for exhale (8 seconds)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred(intensity: 0.6)
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
        // Building energy over 4 seconds
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0,
                duration: 4.0
            )
        ]
        
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.4),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 4.0, value: 0.7)
                ],
                relativeTime: 0
            )
        ]
        
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
    
    private func createHoldPattern() throws -> CHHapticPattern {
        // Sustained tension over 7 seconds
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0,
                duration: 7.0
            )
        ]
        
        return try CHHapticPattern(events: events, parameterCurves: [])
    }
    
    private func createExhalePattern() throws -> CHHapticPattern {
        // Gentle release over 8 seconds
        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: 8.0
            )
        ]
        
        let curves = [
            CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.7),
                    CHHapticParameterCurve.ControlPoint(relativeTime: 8.0, value: 0.1)
                ],
                relativeTime: 0
            )
        ]
        
        return try CHHapticPattern(events: events, parameterCurves: curves)
    }
}

// MARK: - Triangle Shapes

struct TrianglePath: Shape {
    let size: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let cornerRadius: CGFloat = 16
        
        // Create a proper right-angle triangle that fits well on screen
        let triangleWidth = size * 0.7   // Bottom edge - inhale (4s)
        let triangleHeight = size * 0.6  // Right edge - hold (7s)
        
        // Position triangle vertices to create right angle at bottom-right
        let bottomLeft = CGPoint(x: center.x - triangleWidth/2, y: center.y + triangleHeight/2)
        let bottomRight = CGPoint(x: center.x + triangleWidth/2, y: center.y + triangleHeight/2)
        let top = CGPoint(x: center.x - triangleWidth/6, y: center.y - triangleHeight/2)
        
        var path = Path()
        
        // Start from bottom-left corner (after rounding)
        path.move(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y))
        
        // Bottom edge
        path.addLine(to: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y))
        
        // Bottom-right rounded corner
        path.addQuadCurve(to: CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius),
                         control: bottomRight)
        
        // Right edge
        path.addLine(to: CGPoint(x: top.x + cornerRadius * 0.7, y: top.y + cornerRadius * 0.7))
        
        // Top rounded corner
        path.addQuadCurve(to: CGPoint(x: top.x - cornerRadius * 0.7, y: top.y + cornerRadius * 0.7),
                         control: top)
        
        // Left edge
        path.addLine(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius))
        
        // Bottom-left rounded corner
        path.addQuadCurve(to: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y),
                         control: bottomLeft)
        
        return path
    }
}

struct TriangleProgressPath: Shape {
    let size: CGFloat
    let progress: Double
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let cornerRadius: CGFloat = 16
        
        // Create a proper right-angle triangle that fits well on screen
        let triangleWidth = size * 0.7   // Bottom edge - inhale (4s)
        let triangleHeight = size * 0.6  // Right edge - hold (7s)
        
        // Position triangle vertices to create right angle at bottom-right
        let bottomLeft = CGPoint(x: center.x - triangleWidth/2, y: center.y + triangleHeight/2)
        let bottomRight = CGPoint(x: center.x + triangleWidth/2, y: center.y + triangleHeight/2)
        let top = CGPoint(x: center.x - triangleWidth/6, y: center.y - triangleHeight/2)
        
        // Calculate perimeter segments (same as ball calculation)
        let bottomEdge = distance(from: bottomLeft, to: bottomRight) - cornerRadius * 2
        let rightEdge = distance(from: bottomRight, to: top) - cornerRadius * 2  
        let leftEdge = distance(from: top, to: bottomLeft) - cornerRadius * 2
        let cornerLength = CGFloat.pi * cornerRadius / 2
        let totalPerimeter = bottomEdge + rightEdge + leftEdge + cornerLength * 3
        
        let targetDistance = CGFloat(progress) * totalPerimeter
        var currentDistance: CGFloat = 0
        
        var path = Path()
        
        // Start point (bottom-left after corner)
        let startPoint = CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y)
        path.move(to: startPoint)
        
        // Bottom edge
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, bottomEdge)
            let endPoint = CGPoint(
                x: startPoint.x + segmentLength,
                y: startPoint.y
            )
            path.addLine(to: endPoint)
            if targetDistance <= currentDistance + bottomEdge { return path }
        }
        currentDistance += bottomEdge
        
        // Bottom-right corner
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, cornerLength)
            let endAngle = (segmentLength / cornerLength) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: bottomRight.x - cornerRadius, y: bottomRight.y - cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: Double.pi / 2),
                endAngle: Angle(radians: Double.pi / 2 - Double(endAngle)),
                clockwise: true
            )
            if targetDistance <= currentDistance + cornerLength { return path }
        }
        currentDistance += cornerLength
        
        // Right edge
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, rightEdge)
            let startEdgePoint = CGPoint(x: bottomRight.x, y: bottomRight.y - cornerRadius)
            let endEdgePoint = CGPoint(x: top.x, y: top.y + cornerRadius)
            let progress = segmentLength / rightEdge
            let endPoint = CGPoint(
                x: startEdgePoint.x + progress * (endEdgePoint.x - startEdgePoint.x),
                y: startEdgePoint.y + progress * (endEdgePoint.y - startEdgePoint.y)
            )
            path.addLine(to: endPoint)
            if targetDistance <= currentDistance + rightEdge { return path }
        }
        currentDistance += rightEdge
        
        // Top corner
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, cornerLength)
            let endAngle = (segmentLength / cornerLength) * CGFloat.pi / 2
            path.addArc(
                center: top,
                radius: cornerRadius,
                startAngle: Angle(radians: Double.pi / 2),
                endAngle: Angle(radians: Double.pi / 2 + Double(endAngle)),
                clockwise: false
            )
            if targetDistance <= currentDistance + cornerLength { return path }
        }
        currentDistance += cornerLength
        
        // Left edge
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, leftEdge)
            let startEdgePoint = CGPoint(x: top.x - cornerRadius, y: top.y)
            let endEdgePoint = CGPoint(x: bottomLeft.x, y: bottomLeft.y - cornerRadius)
            let progress = segmentLength / leftEdge
            let endPoint = CGPoint(
                x: startEdgePoint.x + progress * (endEdgePoint.x - startEdgePoint.x),
                y: startEdgePoint.y + progress * (endEdgePoint.y - startEdgePoint.y)
            )
            path.addLine(to: endPoint)
            if targetDistance <= currentDistance + leftEdge { return path }
        }
        currentDistance += leftEdge
        
        // Bottom-left corner (final)
        if targetDistance > currentDistance {
            let segmentLength = min(targetDistance - currentDistance, cornerLength)
            let endAngle = (segmentLength / cornerLength) * CGFloat.pi / 2
            path.addArc(
                center: CGPoint(x: bottomLeft.x + cornerRadius, y: bottomLeft.y - cornerRadius),
                radius: cornerRadius,
                startAngle: Angle(radians: Double.pi),
                endAngle: Angle(radians: Double.pi + Double(endAngle)),
                clockwise: false
            )
        }
        
        return path
    }
    
    private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

#Preview {
    TriangleBreathingView(
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
