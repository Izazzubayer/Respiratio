//
//  BackgroundNoiseYouTubeView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI

struct BackgroundNoiseYouTubeView: View {
    @State private var selectedVideoURL: URL? = nil
    @State private var showSheet = false

    let noises = [
        ("White Noise", "https://www.youtube.com/watch?v=lzmSKX5TF3g"),
        ("Brown Noise", "https://www.youtube.com/watch?v=pfbdrBFKSf0&t=807s"),
        ("40 Hz Binaural Beats", "https://www.youtube.com/watch?v=1_G60OdEzXs")
    ]

    var body: some View {
        NavigationView {
            List(noises, id: \.0) { noise in
                VStack(alignment: .leading) {
                    Text(noise.0)
                        .font(.headline)
                    Text("Tap to play audio")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .onTapGesture {
                    if let url = URL(string: noise.1) {
                        selectedVideoURL = url
                        showSheet = true
                    }
                }
            }
            .navigationTitle("Background Noise")
            .sheet(isPresented: $showSheet) {
                if let url = selectedVideoURL {
                    BackgroundNoisePlayerSheet(videoURL: url)
                }
            }
        }
    }
}
