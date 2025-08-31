import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    @State private var isMeditationSessionActive = false
    
    var body: some View {
        ZStack {
            // Global dark background
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area with smooth tab transitions
                TabView(selection: $selectedTab) {
                    MeditationView()
                        .tag(NavTab.meditation)
                    
                    BreathingView()
                        .tag(NavTab.breathing)
                    
                    BackgroundNoiseView()
                        .tag(NavTab.noise)
                }
                .animation(.easeInOut(duration: 0.4), value: selectedTab)
                .onChange(of: selectedTab) { _, newTab in
                    // Only allow tab changes if meditation session is not active
                    if isMeditationSessionActive && newTab != .meditation {
                        // Provide haptic feedback to indicate tabs are disabled
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        // Revert back to meditation tab if session is active
                        selectedTab = .meditation
                        return
                    }
                    
                    // Post notification when tab changes so audio can be paused immediately
                    // But don't post if we're staying on meditation tab (to avoid conflicts)
                    if newTab != .meditation {
                        NotificationCenter.default.post(
                            name: .tabDidChange,
                            object: newTab
                        )
                    }
                }
                
                // Custom navigation bar
                NavBar(selectedTab: $selectedTab, onSameTabTapped: { tab in
                    handleSameTabTapped(tab)
                })
                .disabled(isMeditationSessionActive)
                .opacity(isMeditationSessionActive ? 0.5 : 1.0)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .onReceive(NotificationCenter.default.publisher(for: .meditationSessionStarted)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isMeditationSessionActive = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .meditationSessionEnded)) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                isMeditationSessionActive = false
            }
        }
    }
    
    // MARK: - Same Tab Tapped Handler
    
    private func handleSameTabTapped(_ tab: NavTab) {
        // Trigger haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Post notification to exit current session
        NotificationCenter.default.post(
            name: .exitToMainView,
            object: tab
        )
    }
}

// MARK: - Comprehensive Previews for Real-Time Development

#Preview("Main App - iPhone") {
    ContentView()
}

#Preview("Main App - iPhone Landscape") {
    ContentView()
}

#Preview("Main App - iPad") {
    ContentView()
}

#Preview("Main App - Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Main App - Dynamic Type Large") {
    ContentView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}
