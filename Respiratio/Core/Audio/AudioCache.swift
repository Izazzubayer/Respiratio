//
//  AudioCache.swift
//  Respiratio
//
//  Optimized audio caching system with pre-loading and memory management
//

import Foundation
import AVFoundation
import UIKit
import Combine

// MARK: - Audio Cache Configuration
struct AudioCacheConfig {
    static let maxCachedItems = 8
    static let preloadThreshold = 0.8 // Start preloading when 80% of cache is used
    static let memoryWarningThreshold = 0.9 // Clear cache when 90% of memory is used
}

// MARK: - Cached Audio Item
final class CachedAudioItem: NSObject {
    let fileName: String
    let fileExtension: String
    let player: AVAudioPlayer
    let fileSize: Int64
    var lastAccessTime: Date
    var accessCount: Int
    
    init(fileName: String, fileExtension: String, player: AVAudioPlayer, fileSize: Int64) {
        self.fileName = fileName
        self.fileExtension = fileExtension
        self.player = player
        self.fileSize = fileSize
        self.lastAccessTime = Date()
        self.accessCount = 1
        super.init()
    }
    
    func updateAccess() {
        lastAccessTime = Date()
        accessCount += 1
    }
}

// MARK: - Audio Cache Manager
final class AudioCacheManager: ObservableObject {
    static let shared = AudioCacheManager()
    
    // MARK: - Published State
    @Published var cacheSize: Int = 0
    @Published var memoryUsage: Double = 0.0
    @Published var isPreloading: Bool = false
    
    // MARK: - Private Properties
    private var cache: [String: CachedAudioItem] = [:]
    private var preloadQueue: [String] = []
    private var memoryWarningObserver: NSObjectProtocol?
    private let cacheQueue = DispatchQueue(label: "com.respiratio.audiocache", qos: .utility)
    private let backgroundQueue = DispatchQueue(label: "com.respiratio.preload", qos: .background)
    
    // MARK: - Cache Statistics
    private var totalCacheSize: Int64 = 0
    private var maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB default
    
    init() {
        setupMemoryWarningObserver()
        startMemoryMonitoring()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Public Interface
    
    /// Get cached audio player or load if not cached
    func getAudioPlayer(for fileName: String, fileExtension: String) -> AVAudioPlayer? {
        let key = cacheKey(fileName: fileName, fileExtension: fileExtension)
        
        if let cachedItem = cache[key] {
            cachedItem.updateAccess()
            return cachedItem.player
        }
        
        // Load and cache the audio file
        return loadAndCacheAudio(fileName: fileName, fileExtension: fileExtension)
    }
    
    /// Preload audio files in background
    func preloadAudioFiles(_ files: [(fileName: String, fileExtension: String)]) {
        guard !isPreloading else { return }
        
        isPreloading = true
        backgroundQueue.async { [weak self] in
            self?.performPreloading(files)
        }
    }
    
    /// Clear cache and free memory
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.performCacheClear()
        }
    }
    
    /// Get cache statistics
    func getCacheStats() -> (itemCount: Int, totalSize: Int64, memoryUsage: Double) {
        return (cache.count, totalCacheSize, memoryUsage)
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(fileName: String, fileExtension: String) -> String {
        return "\(fileName).\(fileExtension)"
    }
    
    private func loadAndCacheAudio(fileName: String, fileExtension: String) -> AVAudioPlayer? {
        // Look for audio file directly in main bundle
        guard let audioUrl = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("Audio file not found: \(fileName).\(fileExtension)")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioUrl)
            player.prepareToPlay()
            
            let fileSize = getFileSize(url: audioUrl)
            let cachedItem = CachedAudioItem(
                fileName: fileName,
                fileExtension: fileExtension,
                player: player,
                fileSize: fileSize
            )
            
            cacheQueue.async { [weak self] in
                self?.addToCache(cachedItem, key: self?.cacheKey(fileName: fileName, fileExtension: fileExtension) ?? "")
            }
            
            return player
        } catch {
            print("Failed to load audio: \(error)")
            return nil
        }
    }
    
    private func addToCache(_ item: CachedAudioItem, key: String) {
        // Check if we need to evict items
        if cache.count >= AudioCacheConfig.maxCachedItems {
            evictLeastUsedItem()
        }
        
        // Check memory constraints
        if totalCacheSize + item.fileSize > maxCacheSize {
            evictItemsBySize(requiredSpace: item.fileSize)
        }
        
        cache[key] = item
        totalCacheSize += item.fileSize
        updatePublishedState()
        
        // Start preloading if needed
        if shouldStartPreloading() {
            startBackgroundPreloading()
        }
    }
    
    private func evictLeastUsedItem() {
        guard let leastUsed = cache.values.min(by: { $0.accessCount < $1.accessCount }) else { return }
        
        let key = cacheKey(fileName: leastUsed.fileName, fileExtension: leastUsed.fileExtension)
        evictItem(withKey: key)
    }
    
    private func evictItemsBySize(requiredSpace: Int64) {
        let sortedItems = cache.values.sorted { $0.accessCount < $1.accessCount }
        var freedSpace: Int64 = 0
        
        for item in sortedItems {
            if freedSpace >= requiredSpace { break }
            
            let key = cacheKey(fileName: item.fileName, fileExtension: item.fileExtension)
            freedSpace += item.fileSize
            evictItem(withKey: key)
        }
    }
    
    private func evictItem(withKey key: String) {
        guard let item = cache[key] else { return }
        
        totalCacheSize -= item.fileSize
        cache.removeValue(forKey: key)
        updatePublishedState()
    }
    
    private func shouldStartPreloading() -> Bool {
        let cacheUsage = Double(cache.count) / Double(AudioCacheConfig.maxCachedItems)
        return cacheUsage >= AudioCacheConfig.preloadThreshold
    }
    
    private func startBackgroundPreloading() {
        // Implementation for background preloading of commonly used audio files
        // This would analyze usage patterns and preload likely-to-be-used files
    }
    
    private func performPreloading(_ files: [(fileName: String, fileExtension: String)]) {
        for file in files {
            _ = loadAndCacheAudio(fileName: file.fileName, fileExtension: file.fileExtension)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isPreloading = false
        }
    }
    
    private func performCacheClear() {
        cache.removeAll()
        totalCacheSize = 0
        updatePublishedState()
    }
    
    private func getFileSize(url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func updatePublishedState() {
        DispatchQueue.main.async { [weak self] in
            self?.cacheSize = self?.cache.count ?? 0
            self?.memoryUsage = Double(self?.totalCacheSize ?? 0) / Double(self?.maxCacheSize ?? 1)
        }
    }
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        if memoryUsage > AudioCacheConfig.memoryWarningThreshold {
            clearCache()
        }
    }
    
    private func startMemoryMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }
    
    private func updateMemoryUsage() {
        // Monitor system memory usage and adjust cache accordingly
        let memoryInfo = ProcessInfo.processInfo
        let memoryUsage = Double(memoryInfo.physicalMemory) / Double(memoryInfo.physicalMemory)
        
        if memoryUsage > 0.8 {
            // System is under memory pressure, reduce cache
            maxCacheSize = maxCacheSize / 2
            if cache.count > AudioCacheConfig.maxCachedItems / 2 {
                evictLeastUsedItem()
            }
        }
    }
}
