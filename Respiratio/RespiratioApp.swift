//
//  RespiratioApp.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-20.
//

// FILE: RespiratioApp.swift
import SwiftUI
import AVFoundation

@main
struct RespiratioApp: App {
    init() {
        configureAudioSession()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

private func configureAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
        // Playback that can mix with other audio (Music/Podcasts)
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setPreferredSampleRate(44_100)          // universal
        try session.setPreferredOutputNumberOfChannels(2)   // stereo
        try session.setPreferredIOBufferDuration(0.005)     // ~5 ms (safe for AVAudioPlayer)
        try session.setActive(true, options: [])
    } catch {
        print("AudioSession configure error:", error)
    }
}
