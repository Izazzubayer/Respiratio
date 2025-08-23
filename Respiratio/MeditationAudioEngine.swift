//
//  MeditationAudioEngine.swift
//  Respiratio
//
//  Comprehensive meditation audio engine with full Apple capabilities
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Combine

final class MeditationAudioEngine: NSObject, ObservableObject {
    static let shared = MeditationAudioEngine()
    
    // MARK: - Published State
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7 {
        didSet { 
            player?.volume = isMuted ? 0 : volume
            MPVolumeView.setVolume(volume)
        }
    }
    @Published var isMuted: Bool = false {
        didSet { 
            player?.volume = isMuted ? 0 : volume
            updateNowPlaying()
        }
    }
    @Published var playbackRate: Float = 1.0 {
        didSet {
            player?.rate = playbackRate
            updateNowPlaying()
        }
    }
    
    // MARK: - Computed Properties
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    var remainingTime: TimeInterval {
        max(0, duration - currentTime)
    }
    
    var isNearEnd: Bool {
        remainingTime <= 60 // Last minute
    }
    
    // MARK: - Private Properties
    private var player: AVAudioPlayer?
    private var updateTimer: Timer?
    private var currentMeditationTitle: String = ""
    private var sessionStartTime: Date?
    
    // MARK: - Audio Session Configuration
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay, .mixWithOthers])
            try session.setActive(true)
            
            // Optimize for spoken audio content
            try session.setPreferredSampleRate(44100)
            try session.setPreferredIOBufferDuration(0.005)
            
        } catch {
            print("Failed to configure audio session:", error)
        }
    }
    
    // MARK: - Load Audio
    func loadMeditation(fileName: String, title: String) {
        stop()
        currentMeditationTitle = title
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Meditation audio file not found: \(fileName).mp3")
            return
        }
        
        configureAudioSession()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.enableRate = true // Enable rate control
            player?.volume = isMuted ? 0 : volume
            player?.rate = playbackRate
            player?.prepareToPlay()
            
            duration = player?.duration ?? 0
            currentTime = 0
            
            setupRemoteCommands()
            setupNowPlaying()
            
        } catch {
            print("Failed to load meditation audio:", error)
        }
    }
    
    // MARK: - Playback Controls
    func play() {
        guard let player = player else { return }
        
        configureAudioSession()
        sessionStartTime = Date()
        
        player.play()
        isPlaying = true
        startUpdateTimer()
        updateNowPlaying()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        // Disable idle timer during playback
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        stopUpdateTimer()
        updateNowPlaying()
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopUpdateTimer()
        
        // Clear Now Playing
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        
        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func seek(to time: TimeInterval) {
        guard let player = player else { return }
        
        let clampedTime = max(0, min(time, duration))
        player.currentTime = clampedTime
        currentTime = clampedTime
        updateNowPlaying()
        
        // Light haptic feedback for seeking
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func skipForward(_ seconds: TimeInterval = 30) {
        let newTime = currentTime + seconds
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: TimeInterval = 30) {
        let newTime = currentTime - seconds
        seek(to: newTime)
    }
    
    // MARK: - Timer Management
    private func startUpdateTimer() {
        stopUpdateTimer()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
    }
    
    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateCurrentTime() {
        guard let player = player, isPlaying else { return }
        currentTime = player.currentTime
        
        // Check if meditation is complete
        if currentTime >= duration {
            meditationCompleted()
        }
    }
    
    // MARK: - Session Management
    private func meditationCompleted() {
        stop()
        
        // Success haptic
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // Post completion notification
        NotificationCenter.default.post(name: .meditationCompleted, object: nil)
    }
    
    // MARK: - Now Playing Integration
    private func setupNowPlaying() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentMeditationTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Respiratio"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Meditation"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        
        // Add artwork if available
        if let artwork = createMeditationArtwork() {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlaying() {
        guard var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            setupNowPlaying()
            return
        }
        
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? playbackRate : 0.0
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func createMeditationArtwork() -> MPMediaItemArtwork? {
        let size = CGSize(width: 300, height: 300)
        
        return MPMediaItemArtwork(boundsSize: size) { _ in
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            // Create gradient background
            let context = UIGraphicsGetCurrentContext()
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemTeal.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)
            
            context?.drawLinearGradient(gradient!, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Add meditation symbol
            let symbolSize: CGFloat = 120
            let symbolRect = CGRect(
                x: (size.width - symbolSize) / 2,
                y: (size.height - symbolSize) / 2,
                width: symbolSize,
                height: symbolSize
            )
            
            let config = UIImage.SymbolConfiguration(pointSize: symbolSize, weight: .light)
            let symbol = UIImage(systemName: "leaf.fill", withConfiguration: config)
            UIColor.white.setFill()
            symbol?.draw(in: symbolRect, blendMode: .normal, alpha: 0.8)
            
            return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        }
    }
    
    // MARK: - Remote Commands
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // Stop command
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        
        // Toggle play/pause
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else {
                self.play()
            }
            return .success
        }
        
        // Skip forward
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.skipForward(event.interval)
            return .success
        }
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        
        // Skip backward
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            self?.skipBackward(event.interval)
            return .success
        }
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        
        // Seek command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: event.positionTime)
            return .success
        }
        
        // Rate commands
        commandCenter.changePlaybackRateCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            self?.playbackRate = event.playbackRate
            return .success
        }
        commandCenter.changePlaybackRateCommand.supportedPlaybackRates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    }
    
    deinit {
        stopUpdateTimer()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

// MARK: - AVAudioPlayerDelegate
extension MeditationAudioEngine: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            meditationCompleted()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error:", error?.localizedDescription ?? "Unknown error")
        stop()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let meditationCompleted = Notification.Name("meditationCompleted")
}
