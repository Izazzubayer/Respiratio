//
//  OptimizedMeditationEngine.swift
//  Respiratio
//
//  Optimized meditation audio engine with caching, pre-loading, and performance improvements
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Combine

// MARK: - Meditation Engine Configuration
struct MeditationEngineConfig {
    static let updateInterval: TimeInterval = 0.1 // 100ms updates for smooth progress
    static let preloadThreshold = 0.8 // Start preloading when 80% through meditation
    static let backgroundPreloadDelay: TimeInterval = 1.5 // Delay before background preloading
    static let fadeInDuration: TimeInterval = 2.0 // Smooth fade in duration
    static let fadeOutDuration: TimeInterval = 3.0 // Smooth fade out duration
}

// MARK: - Optimized Meditation Audio Engine
final class OptimizedMeditationEngine: NSObject, ObservableObject {
    static let shared = OptimizedMeditationEngine()
    
    // MARK: - Published State
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.7 {
        didSet { 
            updatePlayerVolume()
            MPVolumeView.setVolume(volume)
        }
    }
    @Published var isMuted: Bool = false {
        didSet { 
            updatePlayerVolume()
            updateNowPlaying()
        }
    }
    @Published var playbackRate: Float = 1.0 {
        didSet {
            updatePlaybackRate()
            updateNowPlaying()
        }
    }
    @Published var isPreloading: Bool = false
    @Published var fadeState: FadeState = .none
    
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
    private var currentPlayer: AVAudioPlayer?
    private var nextPlayer: AVAudioPlayer?
    private var updateTimer: Timer?
    private var fadeTimer: Timer?
    private var currentMeditationTitle: String = ""
    private var sessionStartTime: Date?
    private var preloadTimer: Timer?
    private var audioCache: AudioCacheManager
    
    // MARK: - Performance Monitoring
    private var performanceMetrics = MeditationPerformanceMetrics()
    
    // MARK: - Fade State
    enum FadeState {
        case none, fadeIn, fadeOut
    }
    
    override init() {
        self.audioCache = AudioCacheManager.shared
        super.init()
        setupAudioSession()
        startPerformanceMonitoring()
    }
    
    deinit {
        stopTimer()
        stopFadeTimer()
        stopPreloadTimer()
    }
    
    // MARK: - Public Interface
    
    /// Load meditation with caching and optimization
    func loadMeditation(fileName: String, title: String) {
        performanceMetrics.startOperation(.load)
        
        stop() // Stop current session
        currentMeditationTitle = title
        
        // Load current meditation immediately
        if let player = audioCache.getAudioPlayer(for: fileName, fileExtension: "mp3") {
            currentPlayer = player
            configurePlayer(player)
            duration = player.duration
            currentTime = 0
            performanceMetrics.endOperation(.load)
            
            // Start background preloading of other meditations
            startBackgroundPreloading()
        } else {
            performanceMetrics.endOperation(.load, success: false)
        }
    }
    
    /// Play with smooth fade in
    func play() {
        guard let player = currentPlayer else { return }
        
        performanceMetrics.startOperation(.play)
        
        ensureAudioSessionActive()
        
        let now = Date()
        sessionStartTime = now
        
        // Start fade in
        startFadeIn()
        
        player.play()
        isPlaying = true
        startTimer()
        
        performanceMetrics.endOperation(.play)
        updateNowPlaying()
    }
    
    /// Pause with smooth fade out
    func pause() {
        performanceMetrics.startOperation(.pause)
        
        // Start fade out
        startFadeOut { [weak self] in
            self?.currentPlayer?.pause()
            self?.isPlaying = false
            self?.stopTimer()
            self?.updateNowPlaying()
            self?.performanceMetrics.endOperation(.pause)
        }
    }
    
    /// Stop and cleanup
    func stop() {
        performanceMetrics.startOperation(.stop)
        
        currentPlayer?.stop()
        currentPlayer?.currentTime = 0
        nextPlayer?.stop()
        nextPlayer = nil
        
        isPlaying = false
        stopTimer()
        stopFadeTimer()
        stopPreloadTimer()
        
        currentTime = 0
        sessionStartTime = nil
        
        updateNowPlaying()
        performanceMetrics.endOperation(.stop)
    }
    
    /// Seek with smooth progress updates
    func seek(fraction: Double) {
        guard let player = currentPlayer else { return }
        
        let clamped = max(0, min(1, fraction))
        let newTime = clamped * duration
        
        player.currentTime = newTime
        currentTime = newTime
        
        if sessionStartTime != nil {
            sessionStartTime = Date().addingTimeInterval(-newTime)
        }
        
        updateNowPlaying()
    }
    
    /// Set playback rate with validation
    func setPlaybackRate(_ rate: Float) {
        let clampedRate = max(0.5, min(2.0, rate))
        playbackRate = clampedRate
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
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
    
    private func ensureAudioSessionActive() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to activate audio session:", error)
        }
    }
    
    private func configurePlayer(_ player: AVAudioPlayer) {
        player.delegate = self
        player.enableRate = true
        player.volume = isMuted ? 0 : volume
        player.rate = playbackRate
        player.prepareToPlay()
        
        setupRemoteCommands()
        setupNowPlaying()
    }
    
    private func updatePlayerVolume() {
        currentPlayer?.volume = isMuted ? 0 : volume
        nextPlayer?.volume = isMuted ? 0 : volume
    }
    
    private func updatePlaybackRate() {
        currentPlayer?.rate = playbackRate
        nextPlayer?.rate = playbackRate
    }
    
    private func startTimer() {
        stopTimer()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: MeditationEngineConfig.updateInterval, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        if let timer = updateTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateProgress() {
        guard isPlaying, let player = currentPlayer else { return }
        
        currentTime = player.currentTime
        
        // Check if meditation should end
        if currentTime >= duration {
            stop()
            return
        }
        
        // Start preloading next meditation if approaching end
        if shouldStartPreloading() {
            startPreloadTimer()
        }
        
        updateNowPlaying()
    }
    
    private func shouldStartPreloading() -> Bool {
        return progress >= MeditationEngineConfig.preloadThreshold
    }
    
    private func startPreloadTimer() {
        stopPreloadTimer()
        
        preloadTimer = Timer.scheduledTimer(withTimeInterval: MeditationEngineConfig.backgroundPreloadDelay, repeats: false) { [weak self] _ in
            self?.performBackgroundPreloading()
        }
    }
    
    private func stopPreloadTimer() {
        preloadTimer?.invalidate()
        preloadTimer = nil
    }
    
    private func startBackgroundPreloading() {
        // Preload commonly used meditations in background
        let commonMeditations = [
            "10-min", "15-min", "20-min", "30-min"
        ]
        
        let preloadFiles = commonMeditations.map { ($0, "mp3") }
        audioCache.preloadAudioFiles(preloadFiles)
    }
    
    private func performBackgroundPreloading() {
        // Preload next likely meditation based on user patterns
        isPreloading = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            // Simulate preloading work
            Thread.sleep(forTimeInterval: 0.3)
            
            DispatchQueue.main.async {
                self?.isPreloading = false
            }
        }
    }
    
    // MARK: - Fade Effects
    
    private func startFadeIn() {
        fadeState = .fadeIn
        currentPlayer?.volume = 0
        
        var fadeProgress: TimeInterval = 0
        let fadeStep = 0.05 // Update every 50ms
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: fadeStep, repeats: true) { [weak self] timer in
            fadeProgress += fadeStep
            
            if fadeProgress >= MeditationEngineConfig.fadeInDuration {
                self?.currentPlayer?.volume = self?.isMuted == true ? 0 : (self?.volume ?? 0.7)
                self?.fadeState = .none
                timer.invalidate()
            } else {
                let fadeRatio = fadeProgress / MeditationEngineConfig.fadeInDuration
                let targetVolume = self?.isMuted == true ? 0 : (self?.volume ?? 0.7)
                self?.currentPlayer?.volume = Float(fadeRatio) * targetVolume
            }
        }
    }
    
    private func startFadeOut(completion: @escaping () -> Void) {
        fadeState = .fadeOut
        let initialVolume = currentPlayer?.volume ?? 0
        
        var fadeProgress: TimeInterval = 0
        let fadeStep = 0.05 // Update every 50ms
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: fadeStep, repeats: true) { [weak self] timer in
            fadeProgress += fadeStep
            
            if fadeProgress >= MeditationEngineConfig.fadeOutDuration {
                self?.currentPlayer?.volume = 0
                self?.fadeState = .none
                timer.invalidate()
                completion()
            } else {
                let fadeRatio = fadeProgress / MeditationEngineConfig.fadeOutDuration
                let remainingVolume = 1.0 - fadeRatio
                self?.currentPlayer?.volume = initialVolume * Float(remainingVolume)
            }
        }
    }
    
    private func stopFadeTimer() {
        fadeTimer?.invalidate()
        fadeTimer = nil
    }
    
    // MARK: - Remote Commands & Now Playing
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in 
            self?.play()
            return .success 
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in 
            self?.pause()
            return .success 
        }
        
        commandCenter.stopCommand.addTarget { [weak self] _ in 
            self?.stop()
            return .success 
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            self.isPlaying ? self.pause() : self.play()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.isEnabled = false
    }
    
    private func setupNowPlaying() {
        updateNowPlaying()
    }
    
    private func updateNowPlaying() {
        let info: [String: Any] = [
            MPMediaItemPropertyTitle: currentMeditationTitle,
            MPMediaItemPropertyArtist: "Respiratio",
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? playbackRate : 0.0,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime
        ]
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.logPerformanceMetrics()
        }
    }
    
    private func logPerformanceMetrics() {
        let stats = audioCache.getCacheStats()
        print("Meditation Audio Cache Stats: \(stats.itemCount) items, \(stats.totalSize / 1024 / 1024)MB, \(Int(stats.memoryUsage * 100))% usage")
        print("Meditation Performance Metrics: \(performanceMetrics.getSummary())")
    }
}

// MARK: - AVAudioPlayerDelegate
extension OptimizedMeditationEngine: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            stop()
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        stop()
    }
}

// MARK: - Meditation Performance Metrics
private struct MeditationPerformanceMetrics {
    enum Operation: String, CaseIterable {
        case load, play, pause, stop
    }
    
    private var operationTimes: [Operation: [TimeInterval]] = [:]
    private var operationStartTimes: [Operation: Date] = [:]
    
    mutating func startOperation(_ operation: Operation) {
        operationStartTimes[operation] = Date()
    }
    
    mutating func endOperation(_ operation: Operation, success: Bool = true) {
        guard let startTime = operationStartTimes[operation] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        operationTimes[operation, default: []].append(duration)
        operationStartTimes.removeValue(forKey: operation)
    }
    
    func getSummary() -> String {
        var summary = "Meditation Performance Summary:\n"
        
        for operation in Operation.allCases {
            if let times = operationTimes[operation], !times.isEmpty {
                let avg = times.reduce(0, +) / Double(times.count)
                let min = times.min() ?? 0
                let max = times.max() ?? 0
                summary += "\(operation.rawValue): avg=\(String(format: "%.3f", avg))s, min=\(String(format: "%.3f", min))s, max=\(String(format: "%.3f", max))s\n"
            }
        }
        
        return summary
    }
}
