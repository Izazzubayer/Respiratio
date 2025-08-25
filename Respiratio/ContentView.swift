import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    
    var body: some View {
        ZStack {
            // Global dark background
            Color(hex: "#1A2B7C")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area with slide transitions and swipe gestures
                ZStack {
                    // Meditation View
                    if selectedTab == .meditation {
                        MeditationView()
                            .transition(.move(edge: .leading))
                    }
                    
                    // Breathing View
                    if selectedTab == .breathing {
                        BreathingView()
                            .transition(.move(edge: .trailing))
                    }
                    
                    // Noise View
                    if selectedTab == .noise {
                        BackgroundNoiseView()
                            .transition(.move(edge: .trailing))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: selectedTab)

                
                // Custom navigation bar
                NavBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
