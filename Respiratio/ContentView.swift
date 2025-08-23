import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MeditationView()
                .tabItem { 
                    Label("Meditation", systemImage: "leaf.fill")
                }
                .accessibilityLabel("Meditation tab")

            BreathingView()
                .tabItem { 
                    Label("Breathing", systemImage: "wind") 
                }
                .accessibilityLabel("Breathing exercises tab")

            BackgroundNoiseView()
                .tabItem { 
                    Label("Noise", systemImage: "music.note") 
                }
                .accessibilityLabel("Background noise tab")
        }
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
