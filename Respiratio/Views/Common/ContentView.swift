import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    
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
                
                // Custom navigation bar
                NavBar(selectedTab: $selectedTab, onSameTabTapped: { tab in
                    handleSameTabTapped(tab)
                })
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
