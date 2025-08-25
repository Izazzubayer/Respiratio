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

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct BoxBreathingView: View {
    @State private var isActive = false
    @State private var currentPhase: BreathPhase.Kind = .inhale
    @State private var phaseProgress: CGFloat = 0.0
    @State private var lastHapticPhase = "Inhale"
    
    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                VStack(alignment: .leading, spacing: 15) {
                    // Duration Badge
                    HStack(spacing: 4) {
                        Text("2 Minutes")
                            .font(Font.custom("Anek Gujarati", size: 12).weight(.medium))
                            .foregroundColor(.white)
                    }
                    .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .background(Color(red: 0.36, green: 0.47, blue: 1))
                    .cornerRadius(999)
                    
                    // Title and Description
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 24)
                
                Spacer()
                
                // Breathing Phase Display
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentPhase.rawValue.capitalized)
                            .font(Font.custom("Amagro", size: 24).weight(.bold))
                            .lineSpacing(26)
                            .foregroundColor(.white)
                        Text(getPhaseDescription())
                            .font(Font.custom("Anek Gujarati", size: 18))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Breathing Animation Area
                ZStack {
                    // Main breathing box
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 352, height: 343)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: -4)
                                .stroke(Color.white.opacity(0.5), lineWidth: 4)
                        )
                    
                    // Progress bar
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(width: 101, height: 8)
                        .cornerRadius(100)
                        .offset(x: -113.5, y: -176)
                    
                    // Animated breathing ball
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 45, height: 45)
                        .offset(x: -54.5, y: -176.5)
                        .shadow(
                            color: Color(red: 0.20, green: 0.31, blue: 0.82, opacity: 1),
                            radius: 8, y: 4
                        )
                        .scaleEffect(isActive ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: getPhaseDuration())
                            .repeatForever(autoreverses: true),
                            value: isActive
                        )
                }
                
                Spacer()
                
                // Control Buttons
                HStack(spacing: 18) {
                    Button(action: {
                        startBreathing()
                    }) {
                        HStack(spacing: 4) {
                            Text("Play")
                                .font(Font.custom("Anek Gujarati", size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                        .frame(width: 111)
                        .background(Color(red: 0.17, green: 0.28, blue: 0.79))
                        .cornerRadius(12)
                    }
                    .disabled(isActive)
                    
                    Button(action: {
                        stopBreathing()
                    }) {
                        HStack(spacing: 4) {
                            Text("Stop")
                                .font(Font.custom("Anek Gujarati", size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24))
                        .frame(width: 111)
                        .background(Color(red: 0.84, green: 0.36, blue: 0.28))
                        .cornerRadius(12)
                    }
                    .disabled(!isActive)
                }
                .padding(.bottom, 32)
            }
        }
        .onReceive(timer) { _ in
            if isActive {
                updateBreathingPhase()
            }
        }
    }
    
    // MARK: - Breathing Logic
    
    private func startBreathing() {
        isActive = true
        currentPhase = .inhale
        phaseProgress = 0.0
        lastHapticPhase = "Inhale"
        triggerHapticFeedback()
    }
    
    private func stopBreathing() {
        isActive = false
        phaseProgress = 0.0
    }
    
    private func updateBreathingPhase() {
        let totalDuration: TimeInterval = 8.0 // 2 seconds per phase
        let elapsed = Date().timeIntervalSince1970.truncatingRemainder(dividingBy: totalDuration)
        
        let phaseDuration = totalDuration / 4.0
        let currentPhaseIndex = Int(elapsed / phaseDuration)
        
        let newPhase: BreathPhase.Kind
        switch currentPhaseIndex {
        case 0: newPhase = .inhale
        case 1: newPhase = .hold
        case 2: newPhase = .exhale
        case 3: newPhase = .hold
        default: newPhase = .inhale
        }
        
        if newPhase != currentPhase {
            currentPhase = newPhase
            triggerHapticFeedback()
            lastHapticPhase = newPhase.rawValue.capitalized
        }
        
        // Calculate progress within current phase
        let phaseElapsed = elapsed.truncatingRemainder(dividingBy: phaseDuration)
        phaseProgress = CGFloat(phaseElapsed / phaseDuration)
    }
    
    private func getPhaseDuration() -> Double {
        switch currentPhase {
        case .inhale, .exhale:
            return 2.0
        case .hold:
            return 2.0
        }
    }
    
    private func getPhaseDescription() -> String {
        switch currentPhase {
        case .inhale:
            return "Breathe In Slowly"
        case .hold:
            return "Hold Your Breath"
        case .exhale:
            return "Breathe Out Slowly"
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    BoxBreathingView()
}
