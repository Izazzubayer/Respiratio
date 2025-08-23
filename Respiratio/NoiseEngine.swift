// FILE: NoiseEngine.swift
import Foundation
import AVFoundation
import MediaPlayer
import UIKit

final class NoiseEngine: ObservableObject {
    // ✅ Add this singleton so RespiratioApp can reference .shared
    static let shared = NoiseEngine()

    // MARK: Published UI state
    @Published var isPlaying: Bool = false
    @Published var elapsed: TimeInterval = 0          // seconds since session start (for timed sessions)
    @Published var selectedDuration: BNDuration = .infinite {
        didSet { resetTimerForSelection() }
    }
    @Published var volume: Float = 0.7 {
        didSet { 
            player?.volume = isMuted ? 0 : volume
            // Sync with system volume
            MPVolumeView.setVolume(volume)
        }
    }
    @Published var isMuted: Bool = false {
        didSet { 
            player?.volume = isMuted ? 0 : volume
            updateNowPlaying(isPlaying: isPlaying)
        }
    }

    // MARK: Computed Properties for UI
    var durationSeconds: TimeInterval? { 
        selectedDuration.timeInterval 
    }
    
    var progress: Double {
        guard let total = durationSeconds, total > 0 else { return 0 }
        return max(0, min(1, elapsed / total))
    }
    
    // MARK: Internal
    private var player: AVAudioPlayer?
    private var tickTimer: Timer?
    private var sessionStart: Date?
    private var sessionEnd: Date?
    private var currentNoise: BackgroundNoise?

    // MARK: Setup
    func load(noise: BackgroundNoise) {
        stop() // stop current if any
        currentNoise = noise

        guard let url = Bundle.main.url(forResource: noise.fileName, withExtension: noise.fileExt) else {
            print("Audio file not found:", noise.fileName)
            return
        }

        do {
            // Configure audio session for background playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            
            // AVAudioPlayer is resilient & low‑overhead for looping mp3s
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1          // loop forever (we handle end by timer)
            p.enableRate = false
            p.volume = isMuted ? 0 : volume
            p.prepareToPlay()             // <— important, avoids converter hiccups
            self.player = p
            
            // Setup remote commands for background control
            setupRemoteCommands()
        } catch {
            print("AVAudioPlayer init error:", error)
        }
    }

    // MARK: Transport
    func play() {
        guard let p = player else { return }
        
        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session:", error)
        }
        
        let now = Date()
        sessionStart = now
        if let total = selectedDuration.timeInterval {
            sessionEnd = now.addingTimeInterval(total)
            elapsed = 0
        } else {
            sessionEnd = nil
            elapsed = 0
        }
        p.play()
        isPlaying = true
        startTicking()
        updateNowPlaying(isPlaying: true)
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTicking()
        updateNowPlaying(isPlaying: false)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        stopTicking()
        elapsed = 0
        sessionStart = nil
        sessionEnd = nil
        updateNowPlaying(isPlaying: false)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func nudge(by seconds: TimeInterval) {
        guard let start = sessionStart, let total = selectedDuration.timeInterval else { return }
        let newElapsed = max(0, min(total, elapsed + seconds))
        elapsed = newElapsed
        sessionStart = Date().addingTimeInterval(-newElapsed)
        sessionEnd = start.addingTimeInterval(total)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        updateNowPlaying(isPlaying: isPlaying)
    }

    func seek(fraction: Double) {
        guard let total = selectedDuration.timeInterval else { return }
        let clamped = max(0, min(1, fraction))
        let newElapsed = clamped * total
        elapsed = newElapsed
        sessionStart = Date().addingTimeInterval(-newElapsed)
        updateNowPlaying(isPlaying: isPlaying)
    }

    // MARK: Timer
    private func startTicking() {
        stopTicking()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let t = tickTimer {
            RunLoop.main.add(t, forMode: .common)
        }
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func tick() {
        guard isPlaying else { return }
        if let start = sessionStart, selectedDuration.timeInterval != nil {
            elapsed = Date().timeIntervalSince(start)
        }
        if let end = sessionEnd, Date() >= end {
            stop()
        } else {
            updateNowPlaying(isPlaying: true)
        }
    }

    private func resetTimerForSelection() {
        guard isPlaying else { return }
        let now = Date()
        sessionStart = now
        if let total = selectedDuration.timeInterval {
            sessionEnd = now.addingTimeInterval(total)
            elapsed = 0
        } else {
            sessionEnd = nil
            elapsed = 0
        }
        updateNowPlaying(isPlaying: true)
    }

    // MARK: Now Playing / Remote
    private func updateNowPlaying(isPlaying: Bool) {
        guard let noise = currentNoise else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: noise.title,
            MPMediaItemPropertyArtist: "Respiratio",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let total = selectedDuration.timeInterval {
            info[MPMediaItemPropertyPlaybackDuration] = total
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        } else {
            info[MPNowPlayingInfoPropertyIsLiveStream] = true
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.play(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.pause(); return .success }
        c.stopCommand.addTarget { [weak self] _ in self?.stop(); return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.play()
            return .success
        }
        c.changePlaybackPositionCommand.isEnabled = false
    }
}

// MARK: - MPVolumeView Extension for System Volume Control
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider?.value = volume
        }
    }
}
