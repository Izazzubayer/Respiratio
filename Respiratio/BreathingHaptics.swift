//
//  BreathingHaptics.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import Foundation
import CoreHaptics

class BreathingHaptics {
    private var engine: CHHapticEngine?

    init() {
        prepareHaptics()
    }

    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            engine?.resetHandler = {
                try? self.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Failed to start haptics: \(error)")
        }
    }

    // Public method to create advanced pattern player
    func makePlayer(with pattern: CHHapticPattern) -> CHHapticAdvancedPatternPlayer? {
        guard let engine = engine else { return nil }
        return try? engine.makeAdvancedPlayer(with: pattern)
    }

    // Generate smooth intensity curve for animation & haptics
    func intensityCurve(for stepLabel: String, duration: TimeInterval, fps: Int = 60) -> [Float] {
        var curve = [Float]()
        let steps = Int(duration * Double(fps))
        for i in 0..<steps {
            let t = Double(i) / Double(steps)
            var intensity: Float = 0

            switch stepLabel.lowercased() {
            case "inhale":
                intensity = Float(pow(t, 2))
            case "exhale":
                intensity = 1.0 - Float(t * t)
            case "hold":
                intensity = 1.0
            default:
                intensity = 0.5
            }

            curve.append(intensity)
        }
        return curve
    }
}
