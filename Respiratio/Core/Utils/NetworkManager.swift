//
//  NetworkManager.swift
//  Respiratio
//
//  Network state monitoring and offline functionality management
//

import Foundation
import Network
import Combine
import SystemConfiguration

// MARK: - Network Status
enum NetworkStatus {
    case connected
    case disconnected
    case connecting
    case unknown
}

// MARK: - Connection Type
enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
}

// MARK: - Network Manager
final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    // MARK: - Published State
    @Published var networkStatus: NetworkStatus = .unknown
    @Published var connectionType: ConnectionType = .unknown
    @Published var isReachable: Bool = false
    @Published var lastKnownStatus: NetworkStatus = .unknown
    
    // MARK: - Private Properties
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.respiratio.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    private var reachabilityTimer: Timer?
    
    // MARK: - Configuration
    private let reachabilityTimeout: TimeInterval = 5.0
    private let retryInterval: TimeInterval = 2.0
    private let maxRetryAttempts = 3
    
    init() {
        setupNetworkMonitoring()
        setupReachabilityTimer()
    }
    
    deinit {
        monitor.cancel()
        reachabilityTimer?.invalidate()
    }
    
    // MARK: - Network Monitoring Setup
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: monitorQueue)
    }
    
    private func setupReachabilityTimer() {
        reachabilityTimer = Timer.scheduledTimer(withTimeInterval: reachabilityTimeout, repeats: true) { [weak self] _ in
            self?.checkReachability()
        }
    }
    
    // MARK: - Path Update Handling
    private func handlePathUpdate(_ path: NWPath) {
        let newStatus: NetworkStatus
        let newConnectionType: ConnectionType
        
        switch path.status {
        case .satisfied:
            newStatus = .connected
            newConnectionType = determineConnectionType(path)
        case .unsatisfied:
            newStatus = .disconnected
            newConnectionType = .unknown
        case .requiresConnection:
            newStatus = .connecting
            newConnectionType = .unknown
        @unknown default:
            newStatus = .unknown
            newConnectionType = .unknown
        }
        
        DispatchQueue.main.async {
            self.updateNetworkStatus(newStatus, connectionType: newConnectionType)
        }
    }
    
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    private func updateNetworkStatus(_ status: NetworkStatus, connectionType: ConnectionType) {
        let wasConnected = self.networkStatus == .connected
        let isNowConnected = status == .connected
        
        self.lastKnownStatus = self.networkStatus
        self.networkStatus = status
        self.connectionType = connectionType
        self.isReachable = isNowConnected
        
        // Handle connection state changes
        if wasConnected && !isNowConnected {
            handleDisconnection()
        } else if !wasConnected && isNowConnected {
            handleReconnection()
        }
    }
    
    // MARK: - Reachability Checking
    private func checkReachability() {
        guard networkStatus == .connected else { return }
        
        // Test reachability to a reliable host
        let testURL = URL(string: "https://www.apple.com")!
        let task = URLSession.shared.dataTask(with: testURL) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    self?.isReachable = true
                } else {
                    self?.isReachable = false
                    self?.handleReachabilityFailure()
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Connection State Handling
    private func handleDisconnection() {
        // Notify app components about disconnection
        NotificationCenter.default.post(name: .networkDisconnected, object: nil)
        
        // Switch to offline mode
        switchToOfflineMode()
    }
    
    private func handleReconnection() {
        // Notify app components about reconnection
        NotificationCenter.default.post(name: .networkConnected, object: nil)
        
        // Switch back to online mode
        switchToOnlineMode()
    }
    
    private func handleReachabilityFailure() {
        // Network appears connected but can't reach internet
        NotificationCenter.default.post(name: .networkUnreachable, object: nil)
    }
    
    // MARK: - Offline Mode Management
    private func switchToOfflineMode() {
        // Enable offline features
        AppConfigManager.shared.setOfflineMode(true)
        
        // Preload essential content for offline use
        preloadOfflineContent()
    }
    
    private func switchToOnlineMode() {
        // Disable offline mode
        AppConfigManager.shared.setOfflineMode(false)
        
        // Sync any offline changes
        syncOfflineChanges()
    }
    
    // MARK: - Offline Content Management
    private func preloadOfflineContent() {
        // Ensure essential audio files are cached
        let essentialAudio: [(fileName: String, fileExtension: String)] = [
            ("breath_in", "wav"),
            ("breath_out", "wav"),
            ("meditation_bell", "wav")
        ]
        AudioCacheManager.shared.preloadAudioFiles(essentialAudio)
        
        // Cache user preferences and session data
        UserDefaults.standard.synchronize()
    }
    
    private func syncOfflineChanges() {
        // Sync any data that was created/modified while offline
        // This would typically involve syncing with a backend service
    }
    
    // MARK: - Public Interface
    
    /// Check if app can function offline
    var canFunctionOffline: Bool {
        let audioCache = AudioCacheManager.shared
        let essentialContentCached = audioCache.cacheSize > 0
        
        // Check if user data is available locally
        let userDataAvailable = UserDefaults.standard.object(forKey: "user_preferences") != nil
        
        return essentialContentCached && userDataAvailable
    }
    
    /// Get current network quality score (0-100)
    var networkQualityScore: Int {
        guard networkStatus == .connected else { return 0 }
        
        var score = 100
        
        // Deduct points for poor connection types
        switch connectionType {
        case .cellular:
            score -= 20
        case .unknown:
            score -= 30
        default:
            break
        }
        
        // Deduct points if not reachable
        if !isReachable {
            score -= 40
        }
        
        return max(0, score)
    }
    
    /// Force network status refresh
    func refreshNetworkStatus() {
        checkReachability()
    }
    
    /// Check if specific host is reachable
    func isHostReachable(_ host: String, completion: @escaping (Bool) -> Void) {
        let task = URLSession.shared.dataTask(with: URL(string: "https://\(host)")!) { _, response, error in
            let isReachable = response != nil && error == nil
            DispatchQueue.main.async {
                completion(isReachable)
            }
        }
        task.resume()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkConnected = Notification.Name("networkConnected")
    static let networkDisconnected = Notification.Name("networkDisconnected")
    static let networkUnreachable = Notification.Name("networkUnreachable")
}

// MARK: - AppConfigManager Extension
extension AppConfigManager {
    func setOfflineMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "offline_mode_enabled")
        UserDefaults.standard.synchronize()
    }
    
    var isOfflineModeEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "offline_mode_enabled")
    }
}
