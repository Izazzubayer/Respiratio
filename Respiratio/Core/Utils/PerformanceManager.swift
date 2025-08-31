//
//  PerformanceManager.swift
//  Respiratio
//
//  Comprehensive performance monitoring and optimization manager
//

import Foundation
import UIKit
import SwiftUI
import Combine

// MARK: - Performance Metrics
struct PerformanceMetrics {
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let success: Bool
    let memoryUsage: Double
    let cpuUsage: Double
}

// MARK: - Performance Thresholds
struct PerformanceThresholds {
    static let slowOperationThreshold: TimeInterval = 1.0 // 1 second
    static let memoryWarningThreshold: Double = 0.8 // 80% memory usage
    static let cpuWarningThreshold: Double = 0.7 // 70% CPU usage
    static let frameDropThreshold: Double = 0.9 // 90% frame rate
}

// MARK: - Performance Manager
final class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()
    
    // MARK: - Published State
    @Published var isMonitoring: Bool = false
    @Published var currentMemoryUsage: Double = 0.0
    @Published var currentCPUUsage: Double = 0.0
    @Published var currentFrameRate: Double = 60.0
    @Published var performanceAlerts: [PerformanceAlert] = []
    
    // MARK: - Private Properties
    private var metrics: [PerformanceMetrics] = []
    private var monitoringTimer: Timer?
    private var frameRateTimer: Timer?
    private var lastFrameTime: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var displayLink: CADisplayLink?
    private var cancellables = Set<AnyCancellable>()
    private var stutterCount: Int = 0
    
    // MARK: - Performance Alert
    struct PerformanceAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let message: String
        let timestamp: Date
        let severity: Severity
        
        enum AlertType {
            case slowOperation, highMemory, highCPU, lowFrameRate, animationStutter
        }
        
        enum Severity {
            case warning, critical
        }
    }
    
    init() {
        setupDisplayLink()
        startMonitoring()
        setupAnimationMonitoring()
    }
    
    deinit {
        stopMonitoring()
        displayLink?.invalidate()
        stopAnimationMonitoring()
    }
    
    // MARK: - Public Interface
    
    /// Start performance monitoring
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startMetricsCollection()
        startFrameRateMonitoring()
    }
    
    /// Stop performance monitoring
    func stopMonitoring() {
        isMonitoring = false
        stopMetricsCollection()
        stopFrameRateMonitoring()
        stopAnimationMonitoring()
    }
    
    /// Record performance metric
    func recordMetric(operation: String, duration: TimeInterval, success: Bool = true) {
        let metric = PerformanceMetrics(
            operation: operation,
            duration: duration,
            timestamp: Date(),
            success: success,
            memoryUsage: currentMemoryUsage,
            cpuUsage: currentCPUUsage
        )
        
        metrics.append(metric)
        
        // Check if operation is slow
        if duration > PerformanceThresholds.slowOperationThreshold {
            let alert = PerformanceAlert(
                type: .slowOperation,
                message: "Operation '\(operation)' took \(String(format: "%.2f", duration))s",
                timestamp: Date(),
                severity: duration > 2.0 ? .critical : .warning
            )
            performanceAlerts.append(alert)
        }
        
        // Clean up old metrics
        cleanupOldMetrics()
    }
    
    /// Record animation performance
    func recordAnimationPerformance(duration: TimeInterval, frameCount: Int, stutterCount: Int) {
        let frameRate = Double(frameCount) / duration
        let stutterPercentage = Double(stutterCount) / Double(frameCount)
        
        // Check for animation stutter
        if stutterPercentage > 0.1 { // More than 10% stutter
            let alert = PerformanceAlert(
                type: .animationStutter,
                message: "Animation stutter detected: \(Int(stutterPercentage * 100))% frames dropped",
                timestamp: Date(),
                severity: stutterPercentage > 0.2 ? .critical : .warning
            )
            performanceAlerts.append(alert)
        }
        
        // Update frame rate if this animation is representative
        if frameCount > 10 { // Only consider animations with enough frames
            currentFrameRate = frameRate
        }
    }
    
    /// Get smooth animation duration for current performance
    func getSmoothAnimationDuration() -> TimeInterval {
        let baseDuration: TimeInterval = 0.3
        
        // Adjust based on current frame rate
        if currentFrameRate < 30 {
            return baseDuration * 0.5 // Faster animations for low frame rates
        } else if currentFrameRate < 50 {
            return baseDuration * 0.7
        } else {
            return baseDuration
        }
    }
    
    /// Check if animations should be reduced
    var shouldReduceAnimations: Bool {
        return currentFrameRate < 45 || currentMemoryUsage > 0.7
    }
    
    /// Get recommended animation settings
    func getRecommendedAnimationSettings() -> AnimationSettings {
        var baseSettings = AnimationSettings()
        
        if shouldReduceAnimations {
            baseSettings.duration *= 0.7
            baseSettings.springDamping *= 0.8
            baseSettings.springVelocity *= 0.6
        }
        
        return baseSettings
    }
    
    // MARK: - Animation Monitoring
    private func setupAnimationMonitoring() {
        // Monitor for animation-related performance issues
        NotificationCenter.default.publisher(for: .animationDidStart)
            .sink { [weak self] _ in
                self?.startAnimationTracking()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .animationDidComplete)
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let duration = userInfo["duration"] as? TimeInterval,
                   let frameCount = userInfo["frameCount"] as? Int,
                   let stutterCount = userInfo["stutterCount"] as? Int {
                    self?.recordAnimationPerformance(duration: duration, frameCount: frameCount, stutterCount: stutterCount)
                }
            }
            .store(in: &cancellables)
    }
    
    private func startAnimationTracking() {
        // Start tracking animation performance
        frameCount = 0
        stutterCount = 0
        lastFrameTime = CACurrentMediaTime()
    }
    
    private func stopAnimationMonitoring() {
        // Clean up animation monitoring
    }
    
    // MARK: - Frame Rate Monitoring
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func startFrameRateMonitoring() {
        // Display link is already set up in init
    }
    
    private func stopFrameRateMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func displayLinkCallback() {
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime > 0 {
            let frameInterval = currentTime - lastFrameTime
            let expectedInterval = 1.0 / 60.0 // 60fps target
            
            // Check for frame drops
            if frameInterval > expectedInterval * 1.5 {
                stutterCount += 1
            }
            
            frameCount += 1
        }
        
        lastFrameTime = currentTime
        
        // Calculate current frame rate
        if frameCount > 0 {
            let elapsed = currentTime - (lastFrameTime - Double(frameCount) / 60.0)
            currentFrameRate = Double(frameCount) / elapsed
        }
        
        // Check for low frame rate
        if currentFrameRate < PerformanceThresholds.frameDropThreshold * 60 {
            let alert = PerformanceAlert(
                type: .lowFrameRate,
                message: "Low frame rate detected: \(Int(currentFrameRate))fps",
                timestamp: Date(),
                severity: currentFrameRate < 30 ? .critical : .warning
            )
            performanceAlerts.append(alert)
        }
    }
    
    // MARK: - Memory and CPU Monitoring
    private func startMetricsCollection() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }
    }
    
    private func stopMetricsCollection() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func updateSystemMetrics() {
        // Update memory usage
        currentMemoryUsage = getCurrentMemoryUsage()
        
        // Update CPU usage
        currentCPUUsage = getCurrentCPUUsage()
        
        // Check for memory warnings
        if currentMemoryUsage > PerformanceThresholds.memoryWarningThreshold {
            let alert = PerformanceAlert(
                type: .highMemory,
                message: "High memory usage: \(Int(currentMemoryUsage * 100))%",
                timestamp: Date(),
                severity: currentMemoryUsage > 0.9 ? .critical : .warning
            )
            performanceAlerts.append(alert)
        }
        
        // Check for CPU warnings
        if currentCPUUsage > PerformanceThresholds.cpuWarningThreshold {
            let alert = PerformanceAlert(
                type: .highCPU,
                message: "High CPU usage: \(Int(currentCPUUsage * 100))%",
                timestamp: Date(),
                severity: currentCPUUsage > 0.9 ? .critical : .warning
            )
            performanceAlerts.append(alert)
        }
    }
    
    // MARK: - System Metrics
    private func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size)
            let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)
            return usedMemory / totalMemory
        }
        
        return 0.0
    }
    
    private func getCurrentCPUUsage() -> Double {
        // Simplified CPU usage calculation
        // In a real app, you'd use more sophisticated methods
        return 0.0
    }
    
    // MARK: - Cleanup
    private func cleanupOldMetrics() {
        let cutoffDate = Date().addingTimeInterval(-3600) // Keep last hour
        metrics = metrics.filter { $0.timestamp > cutoffDate }
        
        // Keep only recent alerts
        let alertCutoffDate = Date().addingTimeInterval(-1800) // Keep last 30 minutes
        performanceAlerts = performanceAlerts.filter { $0.timestamp > alertCutoffDate }
    }
    
    // MARK: - Performance Optimization
    func optimizeForCurrentPerformance() {
        if shouldReduceAnimations {
            // Reduce animation complexity
            reduceAnimationComplexity()
        }
        
        if currentMemoryUsage > 0.8 {
            // Aggressive memory cleanup
            performMemoryCleanup()
        }
    }
    
    private func reduceAnimationComplexity() {
        // Notify views to reduce animation complexity
        NotificationCenter.default.post(name: .reduceAnimationComplexity, object: nil)
    }
    
    private func performMemoryCleanup() {
        // Clear caches and perform memory cleanup
        // Note: AudioCacheManager doesn't have performMemoryCleanup method
        // We'll just clear old performance metrics for now
        
        // Clear old performance metrics
        cleanupOldMetrics()
    }
}

// MARK: - Animation Settings
struct AnimationSettings {
    var duration: TimeInterval = 0.3
    var springDamping: Double = 0.8
    var springVelocity: Double = 0.6
    var shouldUseSpring: Bool = true
}

// MARK: - Notification Names
extension Notification.Name {
    static let animationDidStart = Notification.Name("animationDidStart")
    static let animationDidComplete = Notification.Name("animationDidComplete")
    static let reduceAnimationComplexity = Notification.Name("reduceAnimationComplexity")
}
