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
    @Published var selectedDuration: BNDuration = .fiveMin {
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
    
    // Completion callback
    var onSessionComplete: (() -> Void)?

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
            // Configure audio session for background playback and control center
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
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
            setupNowPlaying(isPlaying: false)
            
            // Enable background audio
            UIApplication.shared.beginReceivingRemoteControlEvents()
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
        
        // Disable background audio
        UIApplication.shared.endReceivingRemoteControlEvents()
        
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
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
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
            // Call completion callback
            DispatchQueue.main.async {
                self.onSessionComplete?()
            }
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
            MPMediaItemPropertyAlbumTitle: "Background Noise",
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
    
    private func createNoiseArtwork() -> MPMediaItemArtwork? {
        let size = CGSize(width: 300, height: 300)
        
        return MPMediaItemArtwork(boundsSize: size) { _ in
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            // Create gradient background
            let context = UIGraphicsGetCurrentContext()
            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)
            
            context?.drawLinearGradient(gradient!, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Add noise symbol
            let symbolSize: CGFloat = 120
            let symbolRect = CGRect(
                x: (size.width - symbolSize) / 2,
                y: (size.height - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            
            let config = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .light)
            let symbol = UIImage(systemName: "waveform", withConfiguration: config)
            UIColor.white.setFill()
            symbol?.draw(in: symbolRect, blendMode: .normal, alpha: 0.8)
            
            return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        }
    }

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        
        // Play command
        c.playCommand.addTarget { [weak self] _ in 
            self?.play(); 
            return .success 
        }
        
        // Pause command
        c.pauseCommand.addTarget { [weak self] _ in 
            self?.pause(); 
            return .success 
        }
        
        // Stop command
        c.stopCommand.addTarget { [weak self] _ in 
            self?.stop(); 
            return .success 
        }
        
        // Toggle play/pause
        c.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.play()
            return .success
        }
        
        // Skip forward (30 seconds)
        c.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.nudge(by: event.interval)
            return .success
        }
        c.skipForwardCommand.preferredIntervals = [30]
        
        // Skip backward (30 seconds)
        c.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.nudge(by: -event.interval)
            return .success
        }
        c.skipBackwardCommand.preferredIntervals = [30]
        
        // Seek command (for timed sessions)
        if selectedDuration.timeInterval != nil {
            c.changePlaybackPositionCommand.isEnabled = true
            c.changePlaybackPositionCommand.addTarget { [weak self] event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
                self?.seek(fraction: event.positionTime / (self?.selectedDuration.timeInterval ?? 1))
                return .success
            }
        } else {
                    c.changePlaybackPositionCommand.isEnabled = false
    }
    
    // MARK: - App State Handling
    func handleAppDidEnterBackground() {
        // Ensure audio session stays active in background
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func handleAppWillEnterForeground() {
        // Refresh audio session when returning to foreground
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to refresh audio session:", error)
        }
    }
    
    func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio interruption began (e.g., phone call)
            if isPlaying {
                pause()
            }
        case .ended:
            // Audio interruption ended
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && isPlaying {
                play()
            }
        @unknown default:
            break
        }
    }
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
