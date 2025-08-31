//
//  NotificationExtensions.swift
//  Respiratio
//
//  Notification names for app-wide communication
//
//  Created by AI Assistant on 2024-12-19.
//

import Foundation

// MARK: - Notification Names

extension Notification.Name {
    /// Notification sent when user taps the same tab to exit current session
    static let exitToMainView = Notification.Name("exitToMainView")
    
    /// Notification sent when user switches to a different tab
    static let tabDidChange = Notification.Name("tabDidChange")
    
    /// Notification sent when a meditation session starts
    static let meditationSessionStarted = Notification.Name("meditationSessionStarted")
    
    /// Notification sent when a meditation session ends
    static let meditationSessionEnded = Notification.Name("meditationSessionEnded")
    
    /// Notification sent when a noise session starts
    static let noiseSessionStarted = Notification.Name("noiseSessionStarted")
    
    /// Notification sent when a noise session ends
    static let noiseSessionEnded = Notification.Name("noiseSessionEnded")
}
