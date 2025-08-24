import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    
    var body: some View {
        ZStack {
            // Global dark background
            Color(red: 0.21, green: 0.35, blue: 0.97)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content area with smooth transitions
                ZStack {
                    // Meditation View (Left)
                    if selectedTab == .meditation {
                        MeditationView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                    
                    // Breathing View (Center)
                    if selectedTab == .breathing {
                        BreathingView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                    
                    // Noise View (Right)
                    if selectedTab == .noise {
                        BackgroundNoiseView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    }
                }
                .animation(
                    .timingCurve(0.25, 0.1, 0.25, 1.0, duration: 0.6),
                    value: selectedTab
                )
                
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
