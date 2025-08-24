import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            Group {
                switch selectedTab {
                case .meditation:
                    MeditationView()
                case .breathing:
                    BreathingView()
                case .noise:
                    BackgroundNoiseView()
                }
            }
            
            // Custom navigation bar
            NavBar(selectedTab: $selectedTab)
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
