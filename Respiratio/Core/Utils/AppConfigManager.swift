//
//  AppConfigManager.swift
//  Respiratio
//
//  Optimized app configuration manager with caching policies and performance settings
//

import Foundation
import UIKit
import Combine

// MARK: - App Configuration
struct AppConfiguration {
    // MARK: - Audio Settings
    struct Audio {
        static let defaultSampleRate: Double = 44100
        static let defaultBufferDuration: TimeInterval = 0.005
        static let maxVolume: Float = 1.0
        static let minVolume: Float = 0.0
        static let defaultVolume: Float = 0.7
        static let fadeInDuration: TimeInterval = 2.0
        static let fadeOutDuration: TimeInterval = 3.0
    }
    
    // MARK: - Cache Settings
    struct Cache {
        static let maxAudioCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
        static let maxImageCacheSize: Int64 = 50 * 1024 * 1024  // 50MB
        static let maxCacheItems: Int = 20
        static let cacheExpirationTime: TimeInterval = 24 * 60 * 60 // 24 hours
        static let preloadThreshold: Double = 0.7
    }
    
    // MARK: - Performance Settings
    struct Performance {
        static let targetFrameRate: Double = 60.0
        static let updateInterval: TimeInterval = 0.1
        static let backgroundTaskTimeout: TimeInterval = 30.0
        static let memoryWarningThreshold: Double = 0.8
        static let cpuWarningThreshold: Double = 0.7
    }
    
    // MARK: - UI Settings
    struct UI {
        static let animationDuration: TimeInterval = 0.3
        static let hapticFeedbackEnabled: Bool = true
        static let reducedMotionEnabled: Bool = false
        static let darkModeSupport: Bool = true
        static let accessibilityEnabled: Bool = true
    }
}

// MARK: - App Config Manager
final class AppConfigManager: ObservableObject {
    static let shared = AppConfigManager()
    
    // MARK: - Published State
    @Published var currentConfig: AppConfiguration
    @Published var isOptimizedMode: Bool = false
    @Published var cachePolicy: CachePolicy = .balanced
    @Published var performanceMode: PerformanceMode = .standard
    
    // MARK: - Private Properties
    private var userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration Keys
    private enum ConfigKeys {
        static let isOptimizedMode = "isOptimizedMode"
        static let cachePolicy = "cachePolicy"
        static let performanceMode = "performanceMode"
        static let audioSettings = "audioSettings"
        static let uiSettings = "uiSettings"
        static let lastOptimizationDate = "lastOptimizationDate"
    }
    
    // MARK: - Cache Policy
    enum CachePolicy: String, CaseIterable {
        case aggressive = "aggressive"
        case balanced = "balanced"
        case conservative = "conservative"
        
        var maxCacheSize: Int64 {
            switch self {
            case .aggressive:
                return AppConfiguration.Cache.maxAudioCacheSize * 2
            case .balanced:
                return AppConfiguration.Cache.maxAudioCacheSize
            case .conservative:
                return AppConfiguration.Cache.maxAudioCacheSize / 2
            }
        }
        
        var preloadThreshold: Double {
            switch self {
            case .aggressive:
                return 0.5
            case .balanced:
                return AppConfiguration.Cache.preloadThreshold
            case .conservative:
                return 0.9
            }
        }
    }
    
    // MARK: - Performance Mode
    enum PerformanceMode: String, CaseIterable {
        case powerSaving = "powerSaving"
        case standard = "standard"
        case highPerformance = "highPerformance"
        
        var targetFrameRate: Double {
            switch self {
            case .powerSaving:
                return 30.0
            case .standard:
                return AppConfiguration.Performance.targetFrameRate
            case .highPerformance:
                return 120.0
            }
        }
        
        var updateInterval: TimeInterval {
            switch self {
            case .powerSaving:
                return 0.2
            case .standard:
                return AppConfiguration.Performance.updateInterval
            case .highPerformance:
                return 0.05
            }
        }
    }
    
    init() {
        self.userDefaults = UserDefaults.standard
        self.currentConfig = AppConfiguration()
        
        loadConfiguration()
        setupObservers()
        startConfigurationOptimization()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Interface
    
    /// Apply optimized configuration based on device capabilities
    func applyOptimizedConfiguration() {
        let deviceCapabilities = getDeviceCapabilities()
        
        switch deviceCapabilities {
        case .highEnd:
            performanceMode = .highPerformance
            cachePolicy = .aggressive
        case .midRange:
            performanceMode = .standard
            cachePolicy = .balanced
        case .lowEnd:
            performanceMode = .powerSaving
            cachePolicy = .conservative
        }
        
        isOptimizedMode = true
        saveConfiguration()
        
        // Apply configuration changes
        applyConfigurationChanges()
    }
    
    /// Reset to default configuration
    func resetToDefault() {
        performanceMode = .standard
        cachePolicy = .balanced
        isOptimizedMode = false
        saveConfiguration()
        applyConfigurationChanges()
    }
    
    /// Get current cache configuration
    func getCacheConfiguration() -> (maxSize: Int64, preloadThreshold: Double) {
        return (cachePolicy.maxCacheSize, cachePolicy.preloadThreshold)
    }
    
    /// Get current performance configuration
    func getPerformanceConfiguration() -> (targetFrameRate: Double, updateInterval: TimeInterval) {
        return (performanceMode.targetFrameRate, performanceMode.updateInterval)
    }
    
    /// Check if optimization is needed
    func shouldOptimize() -> Bool {
        let lastOptimization = userDefaults.object(forKey: ConfigKeys.lastOptimizationDate) as? Date ?? Date.distantPast
        let daysSinceLastOptimization = Calendar.current.dateComponents([.day], from: lastOptimization, to: Date()).day ?? 0
        
        return daysSinceLastOptimization >= 7 // Optimize weekly
    }
    
    /// Perform automatic optimization
    func performAutomaticOptimization() {
        guard shouldOptimize() else { return }
        
        _ = getDeviceCapabilities()
        let currentPerformance = getCurrentPerformanceMetrics()
        
        // Adjust configuration based on current performance
        if currentPerformance.memoryUsage > 0.8 {
            cachePolicy = .conservative
        } else if currentPerformance.frameRate < 50 {
            performanceMode = .powerSaving
        }
        
        // Save optimization date
        userDefaults.set(Date(), forKey: ConfigKeys.lastOptimizationDate)
        saveConfiguration()
        
        print("Automatic optimization completed: \(cachePolicy.rawValue) cache, \(performanceMode.rawValue) performance")
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        isOptimizedMode = userDefaults.bool(forKey: ConfigKeys.isOptimizedMode)
        
        if let cachePolicyString = userDefaults.string(forKey: ConfigKeys.cachePolicy),
           let policy = CachePolicy(rawValue: cachePolicyString) {
            cachePolicy = policy
        }
        
        if let performanceModeString = userDefaults.string(forKey: ConfigKeys.performanceMode),
           let mode = PerformanceMode(rawValue: performanceModeString) {
            performanceMode = mode
        }
    }
    
    private func saveConfiguration() {
        userDefaults.set(isOptimizedMode, forKey: ConfigKeys.isOptimizedMode)
        userDefaults.set(cachePolicy.rawValue, forKey: ConfigKeys.cachePolicy)
        userDefaults.set(performanceMode.rawValue, forKey: ConfigKeys.performanceMode)
    }
    
    private func setupObservers() {
        // Monitor configuration changes
        $cachePolicy
            .sink { [weak self] _ in
                self?.saveConfiguration()
            }
            .store(in: &cancellables)
        
        $performanceMode
            .sink { [weak self] _ in
                self?.saveConfiguration()
            }
            .store(in: &cancellables)
    }
    
    private func startConfigurationOptimization() {
        // Check for optimization every hour
        Timer.publish(every: 3600, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performAutomaticOptimization()
            }
            .store(in: &cancellables)
    }
    
    private func applyConfigurationChanges() {
        // Notify other components of configuration changes
        NotificationCenter.default.post(
            name: .appConfigurationDidChange,
            object: self,
            userInfo: [
                "cachePolicy": cachePolicy,
                "performanceMode": performanceMode
            ]
        )
    }
    
    private func getDeviceCapabilities() -> DeviceCapability {
        let processInfo = ProcessInfo.processInfo
        let memory = processInfo.physicalMemory
        let processorCount = processInfo.processorCount
        
        // Determine device capability based on hardware
        if memory >= 8 * 1024 * 1024 * 1024 && processorCount >= 8 { // 8GB RAM, 8+ cores
            return .highEnd
        } else if memory >= 4 * 1024 * 1024 * 1024 && processorCount >= 4 { // 4GB RAM, 4+ cores
            return .midRange
        } else {
            return .lowEnd
        }
    }
    
    private func getCurrentPerformanceMetrics() -> (memoryUsage: Double, frameRate: Double) {
        let performanceManager = PerformanceManager.shared
        return (performanceManager.currentMemoryUsage, performanceManager.currentFrameRate)
    }
}

// MARK: - Device Capability
private enum DeviceCapability {
    case lowEnd, midRange, highEnd
}

// MARK: - Notification Names
extension Notification.Name {
    static let appConfigurationDidChange = Notification.Name("appConfigurationDidChange")
}

// MARK: - Configuration Extensions
extension AppConfiguration {
    /// Get optimized configuration for current device
    static func optimized() -> AppConfiguration {
        let configManager = AppConfigManager.shared
        let config = AppConfiguration()
        
        // Apply performance optimizations
        if configManager.performanceMode == .powerSaving {
            // Note: These would need to be mutable properties to work
            // For now, we'll return the default configuration
        } else if configManager.performanceMode == .highPerformance {
            // Note: These would need to be mutable properties to work
            // For now, we'll return the default configuration
        }
        
        // Apply cache optimizations
        if configManager.cachePolicy == .conservative {
            // Note: These would need to be mutable properties to work
            // For now, we'll return the default configuration
        } else if configManager.cachePolicy == .aggressive {
            // Note: These would need to be mutable properties to work
            // For now, we'll return the default configuration
        }
        
        return config
    }
}
