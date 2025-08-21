//
//  NoisePlayerView.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import SwiftUI
import AVFoundation

struct NoisePlayerView: View {
    let noise: BackgroundNoise
    @Environment(\.presentationMode) var presentationMode
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var timerMinutes: Double = 20
    @State private var timeRemaining: Int = 0
    @State private var countdownTimer: Timer?
    @State private var repeatEnabled = false

    var body: some View {
        VStack(spacing: 30) {
            Text(noise.name)
                .font(.largeTitle)
                .bold()
                .padding()

            // Tags
            HStack {
                ForEach(noise.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                }
            }

            // Timer Display
            Text("Time: \(formatTime(timeRemaining))")
                .font(.title2)
            
            // Timer Slider
            HStack {
                Text("Set Timer")
                Slider(value: $timerMinutes, in: 1...120, step: 1) {
                    Text("Timer")
                } minimumValueLabel: {
                    Text("1")
                } maximumValueLabel: {
                    Text("120")
                }
                .onChange(of: timerMinutes) { newValue in
                    timeRemaining = Int(newValue * 60)
                }
                Text("\(Int(timerMinutes)) min")
            }
            .padding()

            // Controls
            HStack(spacing: 30) {
                Button(isPlaying ? "Pause" : "Play") {
                    togglePlayPause()
                }
                Button("Stop") {
                    stopSound()
                }
                Button(repeatEnabled ? "Repeat ON" : "Repeat OFF") {
                    repeatEnabled.toggle()
                    audioPlayer?.numberOfLoops = repeatEnabled ? -1 : 0
                }
            }
            .padding()
            
            Spacer()
        }
        .onAppear {
            timeRemaining = Int(timerMinutes * 60)
            setupAudio()
        }
    }

    // MARK: - Audio & Timer Functions
    func setupAudio() {
        guard let url = Bundle.main.url(forResource: noise.filename, withExtension: "wav") else {
            print("Audio file not found")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = repeatEnabled ? -1 : 0
        } catch {
            print("Error loading audio: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            countdownTimer?.invalidate()
            isPlaying = false
        } else {
            player.play()
            startCountdown()
            isPlaying = true
        }
    }

    func stopSound() {
        audioPlayer?.stop()
        countdownTimer?.invalidate()
        timeRemaining = Int(timerMinutes * 60)
        isPlaying = false
    }

    func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopSound()
            }
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", minutes, sec)
    }
}
