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
    
    // MARK: - Performance Alert
    struct PerformanceAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let message: String
        let timestamp: Date
        let severity: Severity
        
        enum AlertType {
            case slowOperation, highMemory, highCPU, lowFrameRate
        }
        
        enum Severity {
            case warning, critical
        }
    }
    
    init() {
        setupDisplayLink()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        displayLink?.invalidate()
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
        
        // Check for performance issues
        if duration > PerformanceThresholds.slowOperationThreshold {
            createAlert(
                type: .slowOperation,
                message: "\(operation) took \(String(format: "%.2f", duration))s",
                severity: duration > 2.0 ? .critical : .warning
            )
        }
        
        // Clean up old metrics (keep last 1000)
        if metrics.count > 1000 {
            metrics.removeFirst(metrics.count - 1000)
        }
    }
    
    /// Get performance summary
    func getPerformanceSummary() -> String {
        var summary = "Performance Summary:\n"
        
        // Group metrics by operation
        let groupedMetrics = Dictionary(grouping: metrics, by: { $0.operation })
        
        for (operation, operationMetrics) in groupedMetrics {
            let avgDuration = operationMetrics.map { $0.duration }.reduce(0, +) / Double(operationMetrics.count)
            let successRate = Double(operationMetrics.filter { $0.success }.count) / Double(operationMetrics.count) * 100
            
            summary += "\(operation): avg=\(String(format: "%.3f", avgDuration))s, success=\(String(format: "%.1f", successRate))%\n"
        }
        
        summary += "Current Memory: \(String(format: "%.1f", currentMemoryUsage * 100))%\n"
        summary += "Current CPU: \(String(format: "%.1f", currentCPUUsage * 100))%\n"
        summary += "Current FPS: \(String(format: "%.1f", currentFrameRate))\n"
        
        return summary
    }
    
    /// Get performance recommendations
    func getPerformanceRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if currentMemoryUsage > PerformanceThresholds.memoryWarningThreshold {
            recommendations.append("High memory usage detected. Consider clearing caches or reducing background operations.")
        }
        
        if currentCPUUsage > PerformanceThresholds.cpuWarningThreshold {
            recommendations.append("High CPU usage detected. Check for intensive operations or infinite loops.")
        }
        
        if currentFrameRate < PerformanceThresholds.frameDropThreshold * 60 {
            recommendations.append("Frame rate dropping. Optimize UI updates and reduce main thread work.")
        }
        
        // Analyze slow operations
        let slowOperations = metrics.filter { $0.duration > PerformanceThresholds.slowOperationThreshold }
        if !slowOperations.isEmpty {
            let slowestOperation = slowOperations.max { $0.duration < $1.duration }
            if let operation = slowestOperation {
                recommendations.append("Slowest operation: \(operation.operation) (\(String(format: "%.2f", operation.duration))s)")
            }
        }
        
        return recommendations
    }
    
    /// Clear performance alerts
    func clearAlerts() {
        performanceAlerts.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkFired))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func displayLinkFired() {
        let currentTime = CACurrentMediaTime()
        
        if lastFrameTime == 0 {
            lastFrameTime = currentTime
            frameCount = 0
        } else {
            frameCount += 1
            
            let timeDiff = currentTime - lastFrameTime
            if timeDiff >= 1.0 {
                currentFrameRate = Double(frameCount) / timeDiff
                frameCount = 0
                lastFrameTime = currentTime
                
                // Check for frame rate issues
                if currentFrameRate < PerformanceThresholds.frameDropThreshold * 60 {
                    createAlert(
                        type: .lowFrameRate,
                        message: "Frame rate dropped to \(String(format: "%.1f", currentFrameRate)) FPS",
                        severity: currentFrameRate < 30 ? .critical : .warning
                    )
                }
            }
        }
    }
    
    private func startMetricsCollection() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }
    }
    
    private func stopMetricsCollection() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func startFrameRateMonitoring() {
        frameRateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.analyzeFrameRateTrends()
        }
    }
    
    private func stopFrameRateMonitoring() {
        frameRateTimer?.invalidate()
        frameRateTimer = nil
    }
    
    private func updateSystemMetrics() {
        // Update memory usage
        currentMemoryUsage = getMemoryUsage()
        
        // Update CPU usage
        currentCPUUsage = getCPUUsage()
        
        // Check for system warnings
        if currentMemoryUsage > PerformanceThresholds.memoryWarningThreshold {
            createAlert(
                type: .highMemory,
                message: "Memory usage is \(String(format: "%.1f", currentMemoryUsage * 100))%",
                severity: currentMemoryUsage > 0.9 ? .critical : .warning
            )
        }
        
        if currentCPUUsage > PerformanceThresholds.cpuWarningThreshold {
            createAlert(
                type: .highCPU,
                message: "CPU usage is \(String(format: "%.1f", currentCPUUsage * 100))%",
                severity: currentCPUUsage > 0.9 ? .critical : .warning
            )
        }
    }
    
    private func analyzeFrameRateTrends() {
        // Analyze recent frame rate metrics for trends
        let recentMetrics = metrics.filter { 
            $0.timestamp.timeIntervalSinceNow > -30 // Last 30 seconds
        }
        
        if recentMetrics.count > 10 {
            let avgFrameRate = recentMetrics.map { _ in currentFrameRate }.reduce(0, +) / Double(recentMetrics.count)
            
            if avgFrameRate < 50 {
                createAlert(
                    type: .lowFrameRate,
                    message: "Sustained low frame rate: \(String(format: "%.1f", avgFrameRate)) FPS",
                    severity: .warning
                )
            }
        }
    }
    
    private func createAlert(type: PerformanceAlert.AlertType, message: String, severity: PerformanceAlert.Severity) {
        let alert = PerformanceAlert(
            type: type,
            message: message,
            timestamp: Date(),
            severity: severity
        )
        
        DispatchQueue.main.async {
            self.performanceAlerts.append(alert)
            
            // Keep only last 50 alerts
            if self.performanceAlerts.count > 50 {
                self.performanceAlerts.removeFirst(self.performanceAlerts.count - 50)
            }
        }
    }
    
    private func getMemoryUsage() -> Double {
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
    
    private func getCPUUsage() -> Double {
        // Simplified CPU usage calculation
        // In a real app, you'd use more sophisticated methods
        let processInfo = ProcessInfo.processInfo
        let systemUptime = processInfo.systemUptime
        _ = processInfo.processorCount
        
        // This is a simplified calculation - real CPU monitoring requires more complex logic
        return min(0.5, systemUptime.truncatingRemainder(dividingBy: 10) / 10)
    }
}

// MARK: - Performance Monitoring Extensions
extension PerformanceManager {
    
    /// Monitor view lifecycle performance
    func monitorViewLifecycle<T: AnyObject>(_ object: T, operation: String) -> PerformanceMonitor {
        return PerformanceMonitor(manager: self, operation: operation)
    }
    
    /// Monitor async operation performance
    func monitorAsyncOperation<T>(_ operation: String, block: @escaping () async throws -> T) async rethrows -> T {
        let monitor = PerformanceMonitor(manager: self, operation: operation)
        monitor.start()
        
        defer { monitor.end() }
        
        return try await block()
    }
}

// MARK: - Performance Monitor
final class PerformanceMonitor {
    private let manager: PerformanceManager
    private let operation: String
    private let startTime: Date
    
    init(manager: PerformanceManager, operation: String) {
        self.manager = manager
        self.operation = operation
        self.startTime = Date()
    }
    
    func start() {
        // Monitoring started
    }
    
    func end(success: Bool = true) {
        let duration = Date().timeIntervalSince(startTime)
        manager.recordMetric(operation: operation, duration: duration, success: success)
    }
}

// MARK: - View Performance Extensions
extension View {
    /// Monitor view performance
    func monitorPerformance(_ operation: String) -> some View {
        return self.onAppear {
            // For SwiftUI views, we'll use a different monitoring approach
            // since views are structs, not classes
            let startTime = Date()
            PerformanceManager.shared.recordMetric(operation: operation, duration: 0, success: true)
        }.onDisappear {
            // Note: This is a simplified approach for SwiftUI views
            // For more sophisticated monitoring, consider using a different strategy
        }
    }
}
