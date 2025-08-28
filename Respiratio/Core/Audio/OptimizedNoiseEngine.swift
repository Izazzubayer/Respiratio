//
//  OptimizedNoiseEngine.swift
//  Respiratio
//
//  Optimized noise engine with caching, pre-loading, and performance improvements
//

import Foundation
import AVFoundation
import MediaPlayer
import UIKit
import Combine

// MARK: - Engine Configuration
struct NoiseEngineConfig {
    static let updateInterval: TimeInterval = 0.1 // 100ms updates for smoother progress
    static let preloadThreshold = 0.7 // Start preloading when 70% through current session
    static let backgroundPreloadDelay: TimeInterval = 2.0 // Delay before background preloading
}

// MARK: - Optimized Noise Engine
final class OptimizedNoiseEngine: ObservableObject {
    static let shared = OptimizedNoiseEngine()
    
    // MARK: - Published State
    @Published var isPlaying: Bool = false
    @Published var elapsed: TimeInterval = 0
    @Published var selectedDuration: BNDuration = .infinite
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
    @Published var isPreloading: Bool = false
    
    // MARK: - Computed Properties
    var durationSeconds: TimeInterval? { 
        selectedDuration.timeInterval 
    }
    
    var progress: Double {
        guard let total = durationSeconds, total > 0 else { return 0 }
        return max(0, min(1, elapsed / total))
    }
    
    var remainingTime: TimeInterval {
        guard let total = durationSeconds else { return 0 }
        return max(0, total - elapsed)
    }
    
    // MARK: - Private Properties
    private var currentPlayer: AVAudioPlayer?
    private var nextPlayer: AVAudioPlayer?
    private var updateTimer: Timer?
    private var sessionStart: Date?
    private var sessionEnd: Date?
    private var currentNoise: BackgroundNoise?
    private var preloadTimer: Timer?
    private var audioCache: AudioCacheManager
    
    // MARK: - Performance Monitoring
    private var performanceMetrics = NoisePerformanceMetrics()
    
    init() {
        self.audioCache = AudioCacheManager.shared
        setupAudioSession()
        startPerformanceMonitoring()
    }
    
    deinit {
        stopTimer()
        stopPreloadTimer()
    }
    
    // MARK: - Public Interface
    
    /// Load and prepare noise with caching
    func load(noise: BackgroundNoise) {
        performanceMetrics.startOperation(.load)
        
        stop() // Stop current session
        
        currentNoise = noise
        
        // Load current noise immediately
        if let player = audioCache.getAudioPlayer(for: noise.fileName, fileExtension: noise.fileExt) {
            currentPlayer = player
            configurePlayer(player)
            performanceMetrics.endOperation(.load)
            
            // Start background preloading of other noises
            startBackgroundPreloading()
        } else {
            performanceMetrics.endOperation(.load, success: false)
        }
    }
    
    /// Play with optimized performance
    func play() {
        guard let player = currentPlayer else { return }
        
        performanceMetrics.startOperation(.play)
        
        ensureAudioSessionActive()
        
        let now = Date()
        sessionStart = now
        
        if let total = selectedDuration.timeInterval {
            sessionEnd = now.addingTimeInterval(total)
            elapsed = 0
        } else {
            sessionEnd = nil
            elapsed = 0
        }
        
        player.play()
        isPlaying = true
        startTimer()
        
        performanceMetrics.endOperation(.play)
        updateNowPlaying()
    }
    
    /// Pause with minimal overhead
    func pause() {
        currentPlayer?.pause()
        isPlaying = false
        stopTimer()
        updateNowPlaying()
    }
    
    /// Stop and cleanup
    func stop() {
        currentPlayer?.stop()
        currentPlayer?.currentTime = 0
        nextPlayer?.stop()
        nextPlayer = nil
        
        isPlaying = false
        stopTimer()
        stopPreloadTimer()
        
        elapsed = 0
        sessionStart = nil
        sessionEnd = nil
        
        updateNowPlaying()
    }
    
    /// Seek with smooth progress updates
    func seek(fraction: Double) {
        guard let total = selectedDuration.timeInterval else { return }
        
        let clamped = max(0, min(1, fraction))
        let newElapsed = clamped * total
        elapsed = newElapsed
        
        if sessionStart != nil {
            sessionStart = Date().addingTimeInterval(-newElapsed)
        }
        
        updateNowPlaying()
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(44_100)
            try session.setPreferredOutputNumberOfChannels(2)
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            print("AudioSession setup error:", error)
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
        player.numberOfLoops = -1
        player.enableRate = false
        player.volume = isMuted ? 0 : volume
        player.prepareToPlay()
        
        setupRemoteCommands()
    }
    
    private func updatePlayerVolume() {
        currentPlayer?.volume = isMuted ? 0 : volume
        nextPlayer?.volume = isMuted ? 0 : volume
    }
    
    private func startTimer() {
        stopTimer()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: NoiseEngineConfig.updateInterval, repeats: true) { [weak self] _ in
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
        guard isPlaying, let start = sessionStart else { return }
        
        if let end = sessionEnd {
            elapsed = Date().timeIntervalSince(start)
            
            // Check if session should end
            if Date() >= end {
                stop()
                return
            }
            
            // Start preloading next noise if approaching end
            if shouldStartPreloading() {
                startPreloadTimer()
            }
        } else {
            // Infinite session
            elapsed = Date().timeIntervalSince(start)
        }
        
        updateNowPlaying()
    }
    
    private func shouldStartPreloading() -> Bool {
        guard selectedDuration.timeInterval != nil else { return false }
        return progress >= NoiseEngineConfig.preloadThreshold
    }
    
    private func startPreloadTimer() {
        stopPreloadTimer()
        
        preloadTimer = Timer.scheduledTimer(withTimeInterval: NoiseEngineConfig.backgroundPreloadDelay, repeats: false) { [weak self] _ in
            self?.performBackgroundPreloading()
        }
    }
    
    private func stopPreloadTimer() {
        preloadTimer?.invalidate()
        preloadTimer = nil
    }
    
    private func startBackgroundPreloading() {
        // Preload commonly used noises in background
        let commonNoises: [BackgroundNoise] = NoiseCatalog.all
        
        let preloadFiles = commonNoises.map { ($0.fileName, $0.fileExt) }
        audioCache.preloadAudioFiles(preloadFiles)
    }
    
    private func performBackgroundPreloading() {
        // Preload next likely noise based on user patterns
        // This could analyze usage history to predict next selection
        isPreloading = true
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            // Simulate preloading work
            Thread.sleep(forTimeInterval: 0.5)
            
            DispatchQueue.main.async {
                self?.isPreloading = false
            }
        }
    }
    
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
    
    private func updateNowPlaying() {
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
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.logPerformanceMetrics()
        }
    }
    
    private func logPerformanceMetrics() {
        let stats = audioCache.getCacheStats()
        print("Audio Cache Stats: \(stats.itemCount) items, \(stats.totalSize / 1024 / 1024)MB, \(Int(stats.memoryUsage * 100))% usage")
        print("Performance Metrics: \(performanceMetrics.getSummary())")
    }
}

// MARK: - Performance Metrics
private struct NoisePerformanceMetrics {
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
        var summary = "Noise Performance Summary:\n"
        
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
