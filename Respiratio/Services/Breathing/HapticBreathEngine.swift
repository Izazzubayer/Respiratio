import Foundation
import CoreHaptics
import UIKit

/// Breath-aware haptics using Core Haptics.
/// Stronger, body-like pulses for inhale → hold → exhale.
/// Falls back to UIKit haptics if Core Haptics not available.
final class HapticBreathEngine {

    enum Technique {
        case box, equal, fourSevenEight, resonant, triangle
    }

    enum Phase { case inhale, hold, exhale }

    private var engine: CHHapticEngine?
    private var supportsHaptics = false
    private let technique: Technique

    init(technique: Technique) {
        self.technique = technique
        prepareEngine()
    }

    private func prepareEngine() {
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            engine?.playsHapticsOnly = true
        } catch {
            print("Failed to prepare haptic engine:", error)
            supportsHaptics = false
            engine = nil
        }
    }

    func stop() {
        guard supportsHaptics else { return }
        engine?.stop(completionHandler: nil)
        try? engine?.start()
    }

    // MARK: Public API

    func play(phase: Phase, duration: TimeInterval) {
        guard supportsHaptics else {
            // UIKit fallback
            playUIKitFallback(for: phase)
            return
        }

        do {
            let pattern = try patternFor(phase: phase, duration: duration)
            let player = try engine?.makePlayer(with: pattern)
            try engine?.start()
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern:", error)
            playUIKitFallback(for: phase)
        }
    }
    
    private func playUIKitFallback(for phase: Phase) {
        switch phase {
        case .inhale: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .hold:   UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .exhale: UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    // MARK: Patterns

    private func patternFor(phase: Phase, duration: TimeInterval) throws -> CHHapticPattern {
        switch phase {
        case .inhale: return try inhalePattern(duration: duration)
        case .hold:   return try holdPattern(duration: duration)
        case .exhale: return try exhalePattern(duration: duration)
        }
    }

    private func inhalePattern(duration: TimeInterval) throws -> CHHapticPattern {
        let (i0, i1, s0, s1, curve) = inhaleProfile()
        return try rampPattern(duration: duration,
                               intensityFrom: i0, to: i1,
                               sharpnessFrom: s0, to: s1,
                               curve: curve,
                               includeAttackTransient: true,
                               includeReleaseTransient: false)
    }

    private func holdPattern(duration: TimeInterval) throws -> CHHapticPattern {
        let (intensity, sharpness, pulseInterval) = holdProfile()
        var events: [CHHapticEvent] = []
        var t: TimeInterval = 0
        
        while t < duration {
            let transient = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: t
            )
            events.append(transient)
            t += pulseInterval
        }
        return try CHHapticPattern(events: events, parameterCurves: [])
    }

    private func exhalePattern(duration: TimeInterval) throws -> CHHapticPattern {
        let (i0, i1, s0, s1, curve) = exhaleProfile()
        return try rampPattern(duration: duration,
                               intensityFrom: i0, to: i1,
                               sharpnessFrom: s0, to: s1,
                               curve: curve,
                               includeAttackTransient: false,
                               includeReleaseTransient: true)
    }

    private func rampPattern(duration: TimeInterval,
                             intensityFrom i0: Float, to i1: Float,
                             sharpnessFrom s0: Float, to s1: Float,
                             curve: CHHapticParameterCurve.ControlPointCurve,
                             includeAttackTransient: Bool,
                             includeReleaseTransient: Bool) throws -> CHHapticPattern {

        var events: [CHHapticEvent] = []
        var curves: [CHHapticParameterCurve] = []

        // Base continuous event
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: i0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: s0)
            ],
            relativeTime: 0,
            duration: duration
        )
        events.append(continuous)

        // Curves
        curves.append(curve.parameterCurve(id: .hapticIntensityControl,
                                           from: i0, to: i1, duration: duration))
        curves.append(curve.parameterCurve(id: .hapticSharpnessControl,
                                           from: s0, to: s1, duration: duration))

        // Attack
        if includeAttackTransient {
            events.append(
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.98),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                              ],
                              relativeTime: 0)
            )
        }
        // Release
        if includeReleaseTransient {
            events.append(
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [
                                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.2),
                                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                              ],
                              relativeTime: max(0, duration - 0.02))
            )
        }

        return try CHHapticPattern(events: events, parameterCurves: curves)
    }

    // MARK: Profiles (applied to all techniques)

    private func inhaleProfile() -> (Float, Float, Float, Float, CHHapticParameterCurve.ControlPointCurve) {
        // Strong ramp up for all techniques
        return (0.25, 1.0, 0.35, 0.9, .easeInOut)
    }

    private func holdProfile() -> (Float, Float, TimeInterval) {
        // Strong "heartbeat" pulses
        return (0.45, 0.5, 0.4)
    }

    private func exhaleProfile() -> (Float, Float, Float, Float, CHHapticParameterCurve.ControlPointCurve) {
        // Strong ramp down for all techniques
        return (1.0, 0.05, 0.8, 0.2, .easeOut)
    }
}

// MARK: - Curve helper

extension CHHapticParameterCurve {
    enum ControlPointCurve {
        case linear, easeIn, easeOut, easeInOut, sine

        func parameterCurve(id: CHHapticDynamicParameter.ID,
                            from start: Float,
                            to end: Float,
                            duration: TimeInterval) -> CHHapticParameterCurve {
            let cps: [CHHapticParameterCurve.ControlPoint]
            switch self {
            case .linear:
                cps = [
                    .init(relativeTime: 0, value: start),
                    .init(relativeTime: duration, value: end)
                ]
            case .easeIn:
                cps = [
                    .init(relativeTime: 0, value: start),
                    .init(relativeTime: duration * 0.4, value: (start + end) * 0.35),
                    .init(relativeTime: duration, value: end)
                ]
            case .easeOut:
                cps = [
                    .init(relativeTime: 0, value: start),
                    .init(relativeTime: duration * 0.6, value: (start + end) * 0.75),
                    .init(relativeTime: duration, value: end)
                ]
            case .easeInOut:
                cps = [
                    .init(relativeTime: 0, value: start),
                    .init(relativeTime: duration * 0.5, value: (start + end) * 0.55),
                    .init(relativeTime: duration, value: end)
                ]
            case .sine:
                cps = stride(from: 0.0, through: 1.0, by: 0.25).map { t in
                    let time = duration * t
                    let v = start + (end - start) * Float((sin(Double.pi * t - .pi/2) + 1) / 2)
                    return CHHapticParameterCurve.ControlPoint(relativeTime: time, value: v)
                }
            }
            return CHHapticParameterCurve(parameterID: id, controlPoints: cps, relativeTime: 0)
        }
    }
}
