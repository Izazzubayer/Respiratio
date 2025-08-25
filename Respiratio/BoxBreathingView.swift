//
//  BoxBreathingView.swift
//  Respiratio
//
//  Continuous square motion for 4-4-4-4 box breathing (16s cycle)
//

import SwiftUI
import DotLottie

struct BoxBreathingView: View {
    @State private var isAnimating = false
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    
    // Lottie animation reference
    @State private var breathingAnimation: DotLottieAnimation?
    
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
            if let breathingAnimation = breathingAnimation {
                breathingAnimation.view()
                    .frame(width: 280, height: 280)
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
    }

    // MARK: - Breathing Animation Logic
    
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

        // Start the Lottie animation
        if let breathingAnimation = breathingAnimation {
            breathingAnimation.play()
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
    }

    private func stopBreathingAnimation() {
        isAnimating = false
        
        // Stop the Lottie animation
        if let breathingAnimation = breathingAnimation {
            breathingAnimation.stop()
        }
        
        sessionTimer?.invalidate()
        sessionTimer = nil

        withAnimation(.easeInOut(duration: 0.3)) {
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
