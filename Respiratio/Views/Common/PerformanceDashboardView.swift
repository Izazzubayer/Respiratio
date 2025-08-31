//
//  PerformanceDashboardView.swift
//  Respiratio
//
//  Performance & Reliability monitoring dashboard
//

import SwiftUI
import Combine

// MARK: - Performance Dashboard View
struct PerformanceDashboardView: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var batteryManager = BatteryManager.shared
    @StateObject private var appLauncher = OptimizedAppLauncher()
    
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Picker
                Picker("Dashboard Tab", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Performance").tag(1)
                    Text("Network").tag(2)
                    Text("Battery").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(0)
                    performanceTab.tag(1)
                    networkTab.tag(2)
                    batteryTab.tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            PerformanceSettingsView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Status Overview
            HStack(spacing: 16) {
                StatusCard(
                    title: "Performance",
                    value: "\(Int(performanceManager.currentFrameRate))fps",
                    status: performanceManager.currentFrameRate >= 55 ? .good : .warning,
                    icon: "speedometer"
                )
                
                StatusCard(
                    title: "Network",
                    value: networkManager.networkStatus == .connected ? "Online" : "Offline",
                    status: networkManager.isReachable ? .good : .warning,
                    icon: "network"
                )
                
                StatusCard(
                    title: "Battery",
                    value: "\(batteryManager.batteryLevelPercentage)%",
                    status: batteryManager.isBatteryLow ? .warning : .good,
                    icon: "battery.100"
                )
            }
            .padding(.horizontal, 16)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button("Optimize") {
                    performanceManager.optimizeForCurrentPerformance()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Refresh") {
                    refreshAllMetrics()
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Performance Summary
                PerformanceSummaryCard()
                
                // Network Status
                NetworkStatusCard()
                
                // Battery Status
                BatteryStatusCard()
                
                // Recent Alerts
                RecentAlertsCard()
            }
            .padding(16)
        }
    }
    
    // MARK: - Performance Tab
    private var performanceTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Frame Rate Chart
                FrameRateChartCard()
                
                // Memory Usage
                MemoryUsageCard()
                
                // CPU Usage
                CPUUsageCard()
                
                // Animation Performance
                AnimationPerformanceCard()
            }
            .padding(16)
        }
    }
    
    // MARK: - Network Tab
    private var networkTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Connection Status
                ConnectionStatusCard()
                
                // Network Quality
                NetworkQualityCard()
                
                // Offline Capability
                OfflineCapabilityCard()
                
                // Reachability Test
                ReachabilityTestCard()
            }
            .padding(16)
        }
    }
    
    // MARK: - Battery Tab
    private var batteryTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Battery Level
                BatteryLevelCard()
                
                // Power Mode
                PowerModeCard()
                
                // Power Consumption
                PowerConsumptionCard()
                
                // Optimization Recommendations
                OptimizationRecommendationsCard()
            }
            .padding(16)
        }
    }
    
    // MARK: - Helper Methods
    private func refreshAllMetrics() {
        performanceManager.optimizeForCurrentPerformance()
        networkManager.refreshNetworkStatus()
        batteryManager.refreshPowerMode()
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let title: String
    let value: String
    let status: StatusType
    let icon: String
    
    enum StatusType {
        case good, warning, critical
        
        var color: Color {
            switch self {
            case .good: return .green
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(status.color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Performance Summary Card
struct PerformanceSummaryCard: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.blue)
                Text("Performance Summary")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Frame Rate", value: "\(Int(performanceManager.currentFrameRate))fps")
                MetricRow(label: "Memory Usage", value: "\(Int(performanceManager.currentMemoryUsage * 100))%")
                MetricRow(label: "CPU Usage", value: "\(Int(performanceManager.currentCPUUsage * 100))%")
            }
            
            if performanceManager.shouldReduceAnimations {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Consider reducing animations for better performance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Network Status Card
struct NetworkStatusCard: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.blue)
                Text("Network Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Status", value: String(describing: networkManager.networkStatus).capitalized)
                MetricRow(label: "Connection", value: String(describing: networkManager.connectionType).capitalized)
                MetricRow(label: "Reachable", value: networkManager.isReachable ? "Yes" : "No")
                MetricRow(label: "Quality", value: "\(networkManager.networkQualityScore)/100")
            }
            
            if networkManager.canFunctionOffline {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("App can work offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Battery Status Card
struct BatteryStatusCard: View {
    @StateObject private var batteryManager = BatteryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "battery.100")
                    .foregroundColor(.blue)
                Text("Battery Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Level", value: "\(batteryManager.batteryLevelPercentage)%")
                MetricRow(label: "State", value: String(describing: batteryManager.batteryState).capitalized)
                MetricRow(label: "Power Mode", value: String(describing: batteryManager.powerMode).capitalized)
                MetricRow(label: "Low Power", value: batteryManager.isLowPowerModeEnabled ? "Yes" : "No")
            }
            
            if batteryManager.shouldOptimizeForBattery {
                HStack {
                    Image(systemName: "leaf")
                        .foregroundColor(.green)
                    Text("Battery optimization enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Recent Alerts Card
struct RecentAlertsCard: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                Text("Recent Alerts")
                    .font(.headline)
                Spacer()
            }
            
            if performanceManager.performanceAlerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("No performance issues detected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                ForEach(Array(performanceManager.performanceAlerts.prefix(3))) { alert in
                    HStack {
                        Image(systemName: alert.severity == .critical ? "exclamationmark.octagon" : "exclamationmark.triangle")
                            .foregroundColor(alert.severity == .critical ? .red : .orange)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Supporting Views
struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Additional Card Placeholders
struct FrameRateChartCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Frame Rate Chart")
                    .font(.headline)
                Spacer()
            }
            
            Text("Frame rate monitoring chart would go here")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct MemoryUsageCard: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundColor(.blue)
                Text("Memory Usage")
                    .font(.headline)
                Spacer()
            }
            
            ProgressView(value: performanceManager.currentMemoryUsage)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(performanceManager.currentMemoryUsage * 100))% of available memory")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct CPUUsageCard: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("CPU Usage")
                    .font(.headline)
                Spacer()
            }
            
            ProgressView(value: performanceManager.currentCPUUsage)
                .progressViewStyle(LinearProgressViewStyle())
            
            Text("\(Int(performanceManager.currentCPUUsage * 100))% of CPU capacity")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct AnimationPerformanceCard: View {
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "play.circle")
                    .foregroundColor(.blue)
                Text("Animation Performance")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Recommended Duration", value: "\(String(format: "%.2f", performanceManager.getSmoothAnimationDuration()))s")
                MetricRow(label: "Should Reduce", value: performanceManager.shouldReduceAnimations ? "Yes" : "No")
            }
            
            let settings = performanceManager.getRecommendedAnimationSettings()
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended Settings:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Duration: \(String(format: "%.2f", settings.duration))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Spring Damping: \(String(format: "%.2f", settings.springDamping))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Network Tab Cards
struct ConnectionStatusCard: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                Text("Connection Status")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Network Status", value: String(describing: networkManager.networkStatus).capitalized)
                MetricRow(label: "Connection Type", value: String(describing: networkManager.connectionType).capitalized)
                MetricRow(label: "Reachable", value: networkManager.isReachable ? "Yes" : "No")
                MetricRow(label: "Last Known", value: String(describing: networkManager.lastKnownStatus).capitalized)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct NetworkQualityCard: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar")
                    .foregroundColor(.blue)
                Text("Network Quality")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Quality Score", value: "\(networkManager.networkQualityScore)/100")
                
                let quality = networkManager.networkQualityScore
                if quality >= 80 {
                    Text("Excellent connection quality")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if quality >= 60 {
                    Text("Good connection quality")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Poor connection quality")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct OfflineCapabilityCard: View {
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "icloud.slash")
                    .foregroundColor(.blue)
                Text("Offline Capability")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Can Work Offline", value: networkManager.canFunctionOffline ? "Yes" : "No")
                MetricRow(label: "Essential Content", value: "Cached")
                MetricRow(label: "User Data", value: "Available")
            }
            
            if networkManager.canFunctionOffline {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("All essential features available offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Some features may not work offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct ReachabilityTestCard: View {
    @StateObject private var networkManager = NetworkManager.shared
    @State private var testResults: [String: Bool] = [:]
    @State private var isTesting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.blue)
                Text("Reachability Test")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(["apple.com", "google.com", "github.com"], id: \.self) { host in
                    HStack {
                        Text(host)
                            .foregroundColor(.secondary)
                        Spacer()
                        if let result = testResults[host] {
                            Image(systemName: result ? "checkmark.circle" : "xmark.circle")
                                .foregroundColor(result ? .green : .red)
                        } else {
                            Text("...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Button(isTesting ? "Testing..." : "Test Reachability") {
                testReachability()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTesting)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func testReachability() {
        isTesting = true
        testResults.removeAll()
        
        let hosts = ["apple.com", "google.com", "github.com"]
        var completedTests = 0
        
        for host in hosts {
            networkManager.isHostReachable(host) { isReachable in
                DispatchQueue.main.async {
                    testResults[host] = isReachable
                    completedTests += 1
                    
                    if completedTests == hosts.count {
                        isTesting = false
                    }
                }
            }
        }
    }
}

// MARK: - Battery Tab Cards
struct BatteryLevelCard: View {
    @StateObject private var batteryManager = BatteryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "battery.100")
                    .foregroundColor(.blue)
                Text("Battery Level")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("\(batteryManager.batteryLevelPercentage)%")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                ProgressView(value: batteryManager.batteryLevel)
                    .progressViewStyle(LinearProgressViewStyle())
                
                HStack {
                    Text("Critical")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Spacer()
                    Text("Low")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Spacer()
                    Text("Good")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct PowerModeCard: View {
    @StateObject private var batteryManager = BatteryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.circle")
                    .foregroundColor(.blue)
                Text("Power Mode")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                MetricRow(label: "Current Mode", value: String(describing: batteryManager.powerMode).capitalized)
                MetricRow(label: "Low Power Mode", value: batteryManager.isLowPowerModeEnabled ? "Enabled" : "Disabled")
                MetricRow(label: "Should Optimize", value: batteryManager.shouldOptimizeForBattery ? "Yes" : "No")
            }
            
            let modeDescription = getModeDescription(batteryManager.powerMode)
            Text(modeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func getModeDescription(_ mode: PowerMode) -> String {
        switch mode {
        case .normal:
            return "Full performance mode with all features enabled"
        case .powerSaving:
            return "Reduced performance for better battery life"
        case .ultraPowerSaving:
            return "Minimal performance for maximum battery life"
        }
    }
}

struct PowerConsumptionCard: View {
    @StateObject private var batteryManager = BatteryManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("Power Consumption")
                    .font(.headline)
                Spacer()
            }
            
            let estimate = batteryManager.getPowerConsumptionEstimate()
            VStack(spacing: 8) {
                MetricRow(label: "Current", value: String(format: "%.2f", estimate.current))
                MetricRow(label: "Per Hour", value: String(format: "%.2f", estimate.estimated))
                MetricRow(label: "Mode", value: estimate.mode.rawValue.capitalized)
            }
            
            Text("Estimated power consumption based on current usage patterns")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct OptimizationRecommendationsCard: View {
    @StateObject private var batteryManager = BatteryManager.shared
    @StateObject private var performanceManager = PerformanceManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text("Optimization Recommendations")
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if batteryManager.shouldOptimizeForBattery {
                    RecommendationRow(
                        icon: "battery.25",
                        text: "Enable battery optimization mode",
                        color: .orange
                    )
                }
                
                if performanceManager.shouldReduceAnimations {
                    RecommendationRow(
                        icon: "play.circle",
                        text: "Reduce animation complexity",
                        color: .orange
                    )
                }
                
                if performanceManager.currentMemoryUsage > 0.8 {
                    RecommendationRow(
                        icon: "memorychip",
                        text: "Clear memory caches",
                        color: .red
                    )
                }
                
                if !batteryManager.shouldOptimizeForBattery && performanceManager.currentFrameRate >= 55 {
                    RecommendationRow(
                        icon: "checkmark.circle",
                        text: "Performance is optimal",
                        color: .green
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

struct RecommendationRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Performance Settings View
struct PerformanceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var performanceManager = PerformanceManager.shared
    @StateObject private var batteryManager = BatteryManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                Section("Performance Monitoring") {
                    Toggle("Enable Performance Monitoring", isOn: .constant(true))
                    Toggle("Show Performance Alerts", isOn: .constant(true))
                    Toggle("Auto-Optimize Performance", isOn: .constant(true))
                }
                
                Section("Battery Optimization") {
                    Toggle("Auto-Adjust for Battery", isOn: .constant(true))
                    Toggle("Reduce Animations on Low Battery", isOn: .constant(true))
                    Toggle("Optimize Audio for Battery", isOn: .constant(true))
                }
                
                Section("Network Optimization") {
                    Toggle("Offline Mode Support", isOn: .constant(true))
                    Toggle("Auto-Sync When Online", isOn: .constant(true))
                }
                
                Section("Launch Optimization") {
                    Toggle("Fast Launch Mode", isOn: .constant(true))
                    Toggle("Preload Essential Content", isOn: .constant(true))
                }
            }
            .navigationTitle("Performance Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PerformanceDashboardView()
}
