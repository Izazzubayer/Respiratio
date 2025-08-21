//
//  BackgroundNoisePlayerSheet.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//
import SwiftUI
import WebKit

struct BackgroundNoisePlayerSheet: View {
    let videoURL: URL
    @Environment(\.presentationMode) var presentationMode

    @State private var webView: WKWebView? = nil
    @State private var isPlaying = true
    @State private var timerMinutes: Double = 20
    @State private var timeRemaining: Int = 0
    @State private var countdownTimer: Timer?
    @State private var repeatEnabled = false

    var body: some View {
        VStack(spacing: 30) {
            Text("Playing Audio")
                .font(.title)
                .bold()

            // Timer display
            Text("Time: \(formatTime(timeRemaining))")
                .font(.title2)

            Slider(value: $timerMinutes, in: 1...120, step: 1)
                .onChange(of: timerMinutes) { newValue in
                    timeRemaining = Int(newValue * 60)
                }
            Text("\(Int(timerMinutes)) min")

            // Controls
            HStack(spacing: 30) {
                Button(isPlaying ? "Pause" : "Play") {
                    togglePlayPause()
                }

                Button("Stop") {
                    stopAudio()
                }

                Button(repeatEnabled ? "Repeat ON" : "Repeat OFF") {
                    repeatEnabled.toggle()
                }
            }

            // Hidden YouTube player
            YouTubeAudioView(videoURL: videoURL, player: $webView)
                .frame(width: 1, height: 1)

            Spacer()
        }
        .onAppear {
            timeRemaining = Int(timerMinutes * 60)
            startCountdown()
        }
    }

    // MARK: - Timer
    func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopAudio()
            }
        }
    }

    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", minutes, sec)
    }

    // MARK: - Controls
    func togglePlayPause() {
        guard let webView = webView else { return }
        let jsCommand = isPlaying
            ? "document.getElementById('ytplayer').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":\"\"}', '*');"
            : "document.getElementById('ytplayer').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":\"\"}', '*');"
        webView.evaluateJavaScript(jsCommand, completionHandler: nil)
        isPlaying.toggle()
    }

    func stopAudio() {
        guard let webView = webView else { return }
        let jsCommand = "document.getElementById('ytplayer').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"stopVideo\",\"args\":\"\"}', '*');"
        webView.evaluateJavaScript(jsCommand, completionHandler: nil)
        countdownTimer?.invalidate()
        presentationMode.wrappedValue.dismiss()
    }
}
