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
