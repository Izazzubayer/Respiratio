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
    @StateObject private var audioEngine = MeditationAudioEngine.shared
    
    init() {
        configureAudioSession()
        setupAppStateHandling()
    }

    var body: some Scene {
        WindowGroup { 
            AppRootView()
        }
    }
    
    private func setupAppStateHandling() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            audioEngine.handleAppDidEnterBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            audioEngine.handleAppWillEnterForeground()
        }
        
        // Handle audio interruptions (phone calls, etc.)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            audioEngine.handleAudioInterruption(notification: notification)
        }
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
