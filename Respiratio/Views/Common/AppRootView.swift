//
//  SplashScreenView.swift
//  Respiratio
//  App root view that handles welcome screen logic
//

import SwiftUI

// MARK: - App Root View

struct AppRootView: View {
    /// Persistent storage to ensure welcome screen only appears once
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    
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

// MARK: - Testing Helper

extension AppRootView {
    /// Reset welcome screen for testing purposes
    /// Call this function to show welcome screen again
    /// 
    /// Usage in SwiftUI preview or testing:
    /// AppRootView.resetWelcomeScreen()
    static func resetWelcomeScreen() {
        UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
    }
}

#Preview("App Root - Welcome Screen") {
    AppRootView()
}
