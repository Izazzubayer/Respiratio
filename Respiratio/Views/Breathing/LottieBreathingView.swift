import SwiftUI
import DotLottie

struct LottieBreathingView: View {
    @State private var isPlaying = false
    @State private var sessionTime: TimeInterval = 0.0
    @State private var sessionTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.10, green: 0.17, blue: 0.48)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header Section
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
                    // This is where your Lottie animation will go
                    // You can load from bundle, web, or direct JSON string
                    
                    // Option 1: Load from bundle (recommended for production)
                    // DotLottieAnimation(
                    //     fileName: "box_breathing_animation",
                    //     config: AnimationConfig(autoplay: false, loop: true)
                    // ).view()
                    // .frame(width: 280, height: 280)
                    
                    // Option 2: Load from web URL
                    // DotLottieAnimation(
                    //     webURL: "https://your-domain.com/box_breathing.lottie",
                    //     config: AnimationConfig(autoplay: false, loop: true)
                    // ).view()
                    // .frame(width: 280, height: 280)
                    
                    // Option 3: Load from JSON string (for dynamic content)
                    // DotLottieAnimation(
                    //     animationData: "{\"v\":\"4.8.0\",\"meta\":{\"g\":\"LottieFiles AE...",
                    //     config: AnimationConfig(autoplay: false, loop: true)
                    // ).view()
                    // .frame(width: 280, height: 280)
                    
                    // Placeholder for now
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.5), lineWidth: 8)
                        .frame(width: 280, height: 280)
                        .overlay(
                            Text("Lottie Animation\nPlaceholder")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        )
                }
                
                // Control Buttons
                HStack(spacing: 18) {
                    Button(action: {
                        if isPlaying {
                            pauseBreathingSession()
                        } else {
                            startBreathingSession()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isPlaying ? "Pause" : "Play")
                                .font(Font.custom("Anek Gujarati", size: 16))
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 12, leading: 64, bottom: 12, trailing: 64))
                        .background(Color(red: 0.17, green: 0.28, blue: 0.79))
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        stopBreathingSession()
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
        }
        .frame(width: 430, height: 932)
        .onDisappear {
            stopBreathingSession()
        }
    }
    
    // MARK: - Session Management
    
    private func startBreathingSession() {
        isPlaying = true
        
        // Start session timer for 2 minutes
        sessionTime = 0.0
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sessionTime += 1.0
            if sessionTime >= 120.0 { // 2 minutes
                stopBreathingSession()
                return
            }
        }
        
        // Here you would control the Lottie animation
        // For example, if you have a reference to the animation:
        // lottieAnimation.play()
    }
    
    private func pauseBreathingSession() {
        isPlaying = false
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        // Pause the Lottie animation
        // lottieAnimation.pause()
    }
    
    private func stopBreathingSession() {
        isPlaying = false
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        withAnimation(.easeInOut(duration: 0.3)) {
            sessionTime = 0.0
        }
        
        // Stop and reset the Lottie animation
        // lottieAnimation.stop()
    }
}

#Preview {
    LottieBreathingView()
}
