//
//  BackgroundNoiseView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//
import SwiftUI
import AVFoundation

struct BackgroundNoiseView: View {
    @State private var audioPlayer: AVAudioPlayer?
    @State private var selectedNoise: BackgroundNoise? = nil
    @State private var isPlaying = false
    @State private var timerMinutes: Double = 20
    @State private var repeatEnabled = false
    @State private var countdownTimer: Timer?
    @State private var timeRemaining: Int = 0

    var body: some View {
        NavigationView {
            List(backgroundNoises) { noise in
                VStack(alignment: .leading, spacing: 5) {
                    Text(noise.name)
                        .font(.headline)
                    Text(noise.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    // Tags
                    HStack {
                        ForEach(noise.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(5)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(5)
                        }
                    }
                }
                .padding(.vertical, 5)
                .onTapGesture {
                    selectedNoise = noise
                    playSound(noise)
                }
            }
            .navigationTitle("Background Noise")
            .sheet(item: $selectedNoise) { noise in
                NoisePlayerView(noise: noise)
            }
        }
    }

    func playSound(_ noise: BackgroundNoise) {
        do {
            guard let url = Bundle.main.url(forResource: noise.filename, withExtension: "wav") else {
                print("File not found")
                return
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = repeatEnabled ? -1 : 0
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
