import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MeditationView()
                .tabItem { Label("Meditation", systemImage: "leaf") }

            BreathingView()
                .tabItem { Label("Breathing", systemImage: "wind") }

            BackgroundNoiseView()
                .tabItem { Label("Noise", systemImage: "music.note") }
        }
    }
}

// MARK: - Comprehensive Previews for Real-Time Development

#Preview("Main App - iPhone") {
    ContentView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro")
}

#Preview("Main App - iPhone Landscape") {
    ContentView()
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewInterfaceOrientation(.landscapeLeft)
        .previewDisplayName("iPhone 16 Pro - Landscape")
}

#Preview("Main App - iPad") {
    ContentView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch) (6th generation)"))
        .previewDisplayName("iPad Pro")
}

#Preview("Main App - Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro - Dark Mode")
}

#Preview("Main App - Dynamic Type Large") {
    ContentView()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        .previewDevice(PreviewDevice(rawValue: "iPhone 16 Pro"))
        .previewDisplayName("iPhone 16 Pro - Large Text")
}
