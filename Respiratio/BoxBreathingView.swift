//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI

struct BoxBreathingView: View {
    @State private var animationProgress: CGFloat = 0.0
    @State private var isAnimating = false
    @State private var animationTimer: Timer?
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    
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
            
            // Breathing Box with Moving Circle
            ZStack {
                // Breathing Box Outline
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 8)
                    .frame(width: 280, height: 280)
                
                // Moving Circle with Trail
                Circle()
                    .fill(Color.white)
                    .frame(width: 30, height: 30)
                    .shadow(color: Color(hex: "#5A79FF"), radius: 8)
                    .offset(breathingCircleOffset)
            }
            .offset(x: 0, y: 0)
            
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
                    .padding(EdgeInsets(top: 12, leading: 64, bottom: 12, trailing: 64))
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
                    .padding(EdgeInsets(top: 12, leading: 64, bottom: 12, trailing: 64))
                    .background(Color(red: 0.84, green: 0.36, blue: 0.28))
                    .cornerRadius(12)
                }
            }
            .offset(x: 0, y: 264)
        }
        .frame(width: 430, height: 932)
        .background(Color(red: 0.10, green: 0.17, blue: 0.48))
        .onDisappear {
            stopBreathingAnimation()
        }
    }
    
    // MARK: - Breathing Animation Logic
    
    private var breathingCircleOffset: CGSize {
        let boxWidth: CGFloat = 280
        let boxHeight: CGFloat = 280
        let cornerRadius: CGFloat = 12
        
        // Calculate the path around the rounded rectangle
        let progress = animationProgress
        
        // Define the path segments (4 sides of the box)
        let segment1 = 0.25 // Top edge
        let segment2 = 0.5  // Right edge  
        let segment3 = 0.75 // Bottom edge
        let segment4 = 1.0  // Left edge
        
        let x: CGFloat
        let y: CGFloat
        
        if progress <= segment1 {
            // Top edge: left to right
            let t = progress / segment1
            x = -boxWidth/2 + cornerRadius + (boxWidth - 2*cornerRadius) * t
            y = -boxHeight/2
        } else if progress <= segment2 {
            // Right edge: top to bottom
            let t = (progress - segment1) / (segment2 - segment1)
            x = boxWidth/2
            y = -boxHeight/2 + cornerRadius + (boxHeight - 2*cornerRadius) * t
        } else if progress <= segment3 {
            // Bottom edge: right to left
            let t = (progress - segment2) / (segment3 - segment2)
            x = boxWidth/2 - cornerRadius - (boxWidth - 2*cornerRadius) * t
            y = boxHeight/2
        } else {
            // Left edge: bottom to top
            let t = (progress - segment3) / (segment4 - segment3)
            x = -boxWidth/2
            y = boxHeight/2 - cornerRadius - (boxHeight - 2*cornerRadius) * t
        }
        
        return CGSize(width: x, height: y)
    }
    
    private func startBreathingAnimation() {
        isAnimating = true
        
        // Start session timer for 2 minutes
        sessionTime = 0.0
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sessionTime += 1.0
            if sessionTime >= 120.0 { // 2 minutes
                stopBreathingAnimation()
                return
            }
        }
        
        // Start breathing animation timer with dynamic speed
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/120.0, repeats: true) { _ in
            withAnimation(.linear(duration: 1.0/120.0)) {
                // Calculate dynamic speed based on position
                let dynamicSpeed = calculateDynamicSpeed(progress: animationProgress)
                animationProgress += dynamicSpeed
                
                // Reset to 0 when we reach 1.0 to create the loop
                if animationProgress >= 1.0 {
                    animationProgress = 0.0
                }
            }
        }
    }
    
    private func calculateDynamicSpeed(progress: CGFloat) -> CGFloat {
        let baseSpeed: CGFloat = 0.00052 // Base speed for 120Hz (1.0 / (16 seconds * 120 FPS))
        
        // Calculate which edge we're on and how far along it
        let segment = getCurrentSegment(progress: progress)
        let segmentProgress = getSegmentProgress(progress: progress, segment: segment)
        
        // Apply edge slowdown effect
        let edgeSlowdown = calculateEdgeSlowdown(segmentProgress: segmentProgress)
        
        // Add breathing rhythm variation (0-120Hz equivalent)
        let breathingVariation = sin(progress * 8 * .pi) * 0.0001 // Subtle breathing rhythm
        
        // Add corner slowdown
        let cornerSlowdown = calculateCornerSlowdown(progress: progress)
        
        // Combine all speed factors
        let finalSpeed = baseSpeed * (1.0 - edgeSlowdown - cornerSlowdown) + breathingVariation
        
        return max(finalSpeed, 0.0001) // Ensure minimum speed
    }
    
    private func getCurrentSegment(progress: CGFloat) -> Int {
        if progress <= 0.25 { return 0 }      // Top edge
        else if progress <= 0.5 { return 1 }  // Right edge
        else if progress <= 0.75 { return 2 } // Bottom edge
        else { return 3 }                     // Left edge
    }
    
    private func getSegmentProgress(progress: CGFloat, segment: Int) -> CGFloat {
        let segmentStart: CGFloat
        let segmentEnd: CGFloat
        
        switch segment {
        case 0: // Top edge
            segmentStart = 0.0
            segmentEnd = 0.25
        case 1: // Right edge
            segmentStart = 0.25
            segmentEnd = 0.5
        case 2: // Bottom edge
            segmentStart = 0.5
            segmentEnd = 0.75
        case 3: // Left edge
            segmentStart = 0.75
            segmentEnd = 1.0
        default:
            return 0.0
        }
        
        return (progress - segmentStart) / (segmentEnd - segmentStart)
    }
    
    private func calculateEdgeSlowdown(segmentProgress: CGFloat) -> CGFloat {
        // Slow down movement near the edges (corners) of each segment
        let edgeWidth: CGFloat = 0.15 // 15% of each edge is slower
        
        if segmentProgress <= edgeWidth {
            // Start of edge - slow down
            let t = segmentProgress / edgeWidth
            return 0.6 * (1.0 - t) // 60% slowdown at start
        } else if segmentProgress >= (1.0 - edgeWidth) {
            // End of edge - slow down
            let t = (segmentProgress - (1.0 - edgeWidth)) / edgeWidth
            return 0.6 * t // 60% slowdown at end
        } else {
            // Middle of edge - normal speed
            return 0.0
        }
    }
    
    private func calculateCornerSlowdown(progress: CGFloat) -> CGFloat {
        // Additional slowdown at the exact corners
        let cornerRegions: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0]
        let cornerWidth: CGFloat = 0.02 // 2% around each corner
        
        for corner in cornerRegions {
            let distance = abs(progress - corner)
            if distance < cornerWidth {
                // Maximum slowdown at corners
                let t = distance / cornerWidth
                return 0.8 * (1.0 - t) // 80% slowdown at exact corners
            }
        }
        
        return 0.0
    }
    
    private func pauseBreathingAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func stopBreathingAnimation() {
        isAnimating = false
        animationTimer?.invalidate()
        animationTimer = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            animationProgress = 0.0
            sessionTime = 0.0
        }
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
