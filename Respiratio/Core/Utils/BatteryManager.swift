//
//  BatteryManager.swift
//  Respiratio
//
//  Battery optimization and power management for audio playback
//

import Foundation
import UIKit
import AVFoundation
import Combine

// MARK: - Battery State
enum BatteryState {
    case unknown
    case unplugged
    case charging
    case full
}

// MARK: - Power Mode
enum PowerMode {
    case normal
    case powerSaving
    case ultraPowerSaving
}

// MARK: - Battery Manager
final class BatteryManager: ObservableObject {
    static let shared = BatteryManager()
    
    // MARK: - Published State
    @Published var batteryLevel: Float = 0.0
    @Published var batteryState: BatteryState = .unknown
    @Published var powerMode: PowerMode = .normal
    @Published var isLowPowerModeEnabled: Bool = false
    @Published var shouldOptimizeForBattery: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var batteryMonitoringTimer: Timer?
    private var powerModeTimer: Timer?
    
    // MARK: - Configuration
    private let batteryCheckInterval: TimeInterval = 30.0 // 30 seconds
    private let powerModeCheckInterval: TimeInterval = 60.0 // 1 minute
    private let lowBatteryThreshold: Float = 0.2 // 20%
    private let criticalBatteryThreshold: Float = 0.1 // 10%
    
    init() {
        setupBatteryMonitoring()
        setupPowerModeMonitoring()
        updateBatteryState()
    }
    
    deinit {
        stopBatteryMonitoring()
        powerModeTimer?.invalidate()
    }
    
    // MARK: - Battery Monitoring Setup
    private func setupBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // Monitor battery level changes
        NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryState()
            }
            .store(in: &cancellables)
        
        // Monitor battery state changes
        NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateBatteryState()
            }
            .store(in: &cancellables)
        
        // Monitor low power mode
        NotificationCenter.default.publisher(for: .NSProcessInfoPowerStateDidChange)
            .sink { [weak self] _ in
                self?.updatePowerMode()
            }
            .store(in: &cancellables)
        
        // Start periodic monitoring
        startBatteryMonitoring()
    }
    
    private func setupPowerModeMonitoring() {
        powerModeTimer = Timer.scheduledTimer(withTimeInterval: powerModeCheckInterval, repeats: true) { [weak self] _ in
            self?.updatePowerMode()
        }
    }
    
    private func startBatteryMonitoring() {
        batteryMonitoringTimer = Timer.scheduledTimer(withTimeInterval: batteryCheckInterval, repeats: true) { [weak self] _ in
            self?.updateBatteryState()
        }
    }
    
    private func stopBatteryMonitoring() {
        batteryMonitoringTimer?.invalidate()
        batteryMonitoringTimer = nil
    }
    
    // MARK: - Battery State Updates
    private func updateBatteryState() {
        let device = UIDevice.current
        
        // Update battery level
        batteryLevel = device.batteryLevel
        
        // Update battery state
        switch device.batteryState {
        case .unknown:
            batteryState = .unknown
        case .unplugged:
            batteryState = .unplugged
        case .charging:
            batteryState = .charging
        case .full:
            batteryState = .full
        @unknown default:
            batteryState = .unknown
        }
        
        // Update power mode based on battery state
        updatePowerMode()
        
        // Check if we should optimize for battery
        shouldOptimizeForBattery = calculateShouldOptimizeForBattery()
        
        // Post notification for battery state change
        NotificationCenter.default.post(name: .batteryStateChanged, object: nil)
    }
    
    private func updatePowerMode() {
        let processInfo = ProcessInfo.processInfo
        
        // Check system low power mode
        isLowPowerModeEnabled = processInfo.isLowPowerModeEnabled
        
        // Determine power mode based on battery level and system state
        let newPowerMode: PowerMode
        
        if isLowPowerModeEnabled || batteryLevel <= criticalBatteryThreshold {
            newPowerMode = .ultraPowerSaving
        } else if batteryLevel <= lowBatteryThreshold {
            newPowerMode = .powerSaving
        } else {
            newPowerMode = .normal
        }
        
        // Update power mode if changed
        if newPowerMode != powerMode {
            powerMode = newPowerMode
            applyPowerModeSettings()
        }
    }
    
    private func calculateShouldOptimizeForBattery() -> Bool {
        return batteryLevel <= lowBatteryThreshold || 
               isLowPowerModeEnabled || 
               powerMode != .normal
    }
    
    // MARK: - Power Mode Settings
    private func applyPowerModeSettings() {
        switch powerMode {
        case .normal:
            applyNormalPowerSettings()
        case .powerSaving:
            applyPowerSavingSettings()
        case .ultraPowerSaving:
            applyUltraPowerSavingSettings()
        }
        
        // Notify components about power mode change
        NotificationCenter.default.post(name: .powerModeChanged, object: powerMode)
    }
    
    private func applyNormalPowerSettings() {
        // Normal audio quality and performance
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        
        // Enable all features
        AppConfigManager.shared.setPowerMode(.normal)
    }
    
    private func applyPowerSavingSettings() {
        // Reduced audio quality for power saving
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        
        // Enable power saving features
        AppConfigManager.shared.setPowerMode(.powerSaving)
        
        // Reduce animation complexity
        reduceAnimationComplexity()
    }
    
    private func applyUltraPowerSavingSettings() {
        // Minimal audio quality for maximum power saving
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        
        // Enable ultra power saving features
        AppConfigManager.shared.setPowerMode(.powerSaving)
        
        // Minimize all animations and effects
        minimizeAnimationsAndEffects()
    }
    
    // MARK: - Animation Optimization
    private func reduceAnimationComplexity() {
        // Reduce animation duration and complexity
        UIView.animate(withDuration: 0.2) {
            // Apply reduced animation settings
        }
    }
    
    private func minimizeAnimationsAndEffects() {
        // Disable most animations and visual effects
        UIView.animate(withDuration: 0.1) {
            // Apply minimal animation settings
        }
    }
    
    // MARK: - Audio Optimization
    func optimizeAudioForBattery() {
        guard shouldOptimizeForBattery else { return }
        
        switch powerMode {
        case .powerSaving:
            // Reduce audio quality
            try? AVAudioSession.sharedInstance().setPreferredSampleRate(22050)
            try? AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.1)
        case .ultraPowerSaving:
            // Minimal audio quality
            try? AVAudioSession.sharedInstance().setPreferredSampleRate(16000)
            try? AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.2)
        default:
            break
        }
    }
    
    // MARK: - Background Processing Optimization
    func optimizeBackgroundProcessing() {
        guard shouldOptimizeForBattery else { return }
        
        switch powerMode {
        case .powerSaving:
            // Reduce background processing frequency
            AppConfigManager.shared.setBackgroundProcessingInterval(60.0) // 1 minute
        case .ultraPowerSaving:
            // Minimal background processing
            AppConfigManager.shared.setBackgroundProcessingInterval(300.0) // 5 minutes
        default:
            // Normal background processing
            AppConfigManager.shared.setBackgroundProcessingInterval(30.0) // 30 seconds
        }
    }
    
    // MARK: - Public Interface
    
    /// Get battery level as percentage
    var batteryLevelPercentage: Int {
        return Int(batteryLevel * 100)
    }
    
    /// Check if battery is critically low
    var isBatteryCritical: Bool {
        return batteryLevel <= criticalBatteryThreshold
    }
    
    /// Check if battery is low
    var isBatteryLow: Bool {
        return batteryLevel <= lowBatteryThreshold
    }
    
    /// Get recommended audio quality for current power mode
    var recommendedAudioQuality: AudioQuality {
        switch powerMode {
        case .normal:
            return .high
        case .powerSaving:
            return .medium
        case .ultraPowerSaving:
            return .low
        }
    }
    
    /// Get recommended animation duration for current power mode
    var recommendedAnimationDuration: TimeInterval {
        switch powerMode {
        case .normal:
            return 0.3
        case .powerSaving:
            return 0.2
        case .ultraPowerSaving:
            return 0.1
        }
    }
    
    /// Force power mode update
    func refreshPowerMode() {
        updatePowerMode()
    }
    
    /// Get power consumption estimate
    func getPowerConsumptionEstimate() -> PowerConsumptionEstimate {
        let baseConsumption: Double = 1.0 // Base consumption unit
        
        var multiplier: Double = 1.0
        
        switch powerMode {
        case .normal:
            multiplier = 1.0
        case .powerSaving:
            multiplier = 0.7
        case .ultraPowerSaving:
            multiplier = 0.4
        }
        
        // Adjust based on battery level
        if batteryLevel <= lowBatteryThreshold {
            multiplier *= 0.8
        }
        
        return PowerConsumptionEstimate(
            current: baseConsumption * multiplier,
            estimated: baseConsumption * multiplier * 60, // Per hour estimate
            mode: powerMode
        )
    }
}

// MARK: - Supporting Types
enum AudioQuality {
    case low, medium, high
}

struct PowerConsumptionEstimate {
    let current: Double
    let estimated: Double
    let mode: PowerMode
}

// MARK: - Notification Names
extension Notification.Name {
    static let batteryStateChanged = Notification.Name("batteryStateChanged")
    static let powerModeChanged = Notification.Name("powerModeChanged")
}

// MARK: - AppConfigManager Extension
extension AppConfigManager {
    func setPowerMode(_ mode: PowerMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: "power_mode")
        UserDefaults.standard.synchronize()
    }
    
    func setBackgroundProcessingInterval(_ interval: TimeInterval) {
        UserDefaults.standard.set(interval, forKey: "background_processing_interval")
        UserDefaults.standard.synchronize()
    }
    
    var backgroundProcessingInterval: TimeInterval {
        return UserDefaults.standard.double(forKey: "background_processing_interval")
    }
}

// MARK: - PowerMode RawValue
extension PowerMode: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "normal":
            self = .normal
        case "powerSaving":
            self = .powerSaving
        case "ultraPowerSaving":
            self = .ultraPowerSaving
        default:
            return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .normal:
            return "normal"
        case .powerSaving:
            return "powerSaving"
        case .ultraPowerSaving:
            return "ultraPowerSaving"
        }
    }
}
