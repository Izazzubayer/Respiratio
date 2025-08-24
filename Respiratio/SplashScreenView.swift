//
//  SplashScreenView.swift
//  Respiratio
//  Apple HIG-compliant splash screen with fade animations
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            // Background - pure black for dramatic effect
            Color.black
                .ignoresSafeArea(.all)
            
            // Splash image - full screen coverage, static positioning
            Image("SplashScreen")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea(.all) // Ensure full screen coverage
                .opacity(opacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Explicit full screen
        .statusBarHidden() // Hide status bar during splash
        .onAppear {
            // Fade in animation (0.8 seconds) - image stays static
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1.0
            }
            
            // Start countdown after fade in completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
                // Fade out animation (0.8 seconds) - image stays static
                withAnimation(.easeIn(duration: 0.8)) {
                    opacity = 0.0
                }
                
                // Mark as inactive after fade out
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    isActive = true
                }
            }
        }
    }
}

// MARK: - App Root View

struct AppRootView: View {
    @State private var hasSeenWelcome = false
    
    var body: some View {
        if hasSeenWelcome {
            ContentView()
        } else {
            WelcomeView(onGetStarted: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    hasSeenWelcome = true
                }
            })
        }
    }
}

#Preview {
    SplashScreenView()
}
