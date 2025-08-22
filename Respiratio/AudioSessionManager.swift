//
//  AudioSessionManager.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-22.
//

import AVFoundation

enum AudioSessionManager {
    static func activate() {
        let s = AVAudioSession.sharedInstance()
        do {
            try s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try s.setActive(true)
        } catch {
            print("AudioSession activate error:", error)
        }
    }

    static func deactivate() {
        let s = AVAudioSession.sharedInstance()
        do { try s.setActive(false, options: [.notifyOthersOnDeactivation]) }
        catch { print("AudioSession deactivate error:", error) }
    }
}
