//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI
// import DotLottie  // Temporarily commented out until package is properly linked

struct BoxBreathingViewOriginal: View {
    @State private var animationProgress: CGFloat = 0.0
    @State private var isAnimating = false
    @State private var animationTimer: Timer?
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    
    // Lottie animation reference (temporarily disabled)
    // @State private var breathingAnimation: DotLottieAnimation?
    
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

            // Breathing Box with Custom Animation (Lottie temporarily disabled)
            ZStack {
                // Breathing Box Outline
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.5), lineWidth: 8)
                    .frame(width: 280, height: 280)

                // Custom moving circle (your existing animation)
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
        .onAppear {
            // setupLottieAnimation()  // Temporarily disabled
        }
        .onDisappear {
            stopBreathingAnimation()
        }
    }

    // MARK: - Lottie Animation Setup (Temporarily Disabled)
    
    /*
    private func setupLottieAnimation() {
        // Try to load Lottie animation from bundle
        // If it doesn't exist, fall back to custom animation
        if let _ = Bundle.main.path(forResource: "box_breathing", ofType: "lottie") {
            breathingAnimation = DotLottieAnimation(
                fileName: "box_breathing",
                config: AnimationConfig(autoplay: false, loop: true)
            )
        } else if let _ = Bundle.main.path(forResource: "box_breathing", ofType: "json") {
            breathingAnimation = DotLottieAnimation(
                fileName: "box_breathing",
                config: AnimationConfig(autoplay: false, loop: true)
            )
        }
        // If no Lottie file exists, breathingAnimation remains nil and custom animation is used
    }
    */

    // MARK: - Breathing Animation Logic (Custom Fallback)

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

        // Use custom breathing animation (Lottie temporarily disabled)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            withAnimation(.linear(duration: 1.0/60.0)) {
                animationProgress += 0.00104 // 1.0 / (16 seconds * 60 FPS)

                // Reset to 0 when we reach 1.0 to create the loop
                if animationProgress >= 1.0 {
                    animationProgress = 0.0
                }
            }
        }
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

#Preview {
    BoxBreathingViewOriginal()
}
