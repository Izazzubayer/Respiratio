import SwiftUI

struct ContentView: View {
    @State private var selectedTab: NavTab = .meditation
    
    var body: some View {
        ZStack {
            // Global dark background
            Color(red: 0.102, green: 0.168, blue: 0.486)
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
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.4), value: selectedTab)
                
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
