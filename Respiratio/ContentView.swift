//
//  ContentView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            MeditationView()
                .tabItem {
                    Label("Meditation", systemImage: "leaf")
                }
            
            BreathingView()
                .tabItem {
                    Label("Breathing", systemImage: "wind")
                }
            
            BackgroundNoiseView()
                .tabItem {
                    Label("Noise", systemImage: "music.note")
                }
        }
    }
}
