//
//  NoiseLiveActivityManager.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-22.
//
import ActivityKit

enum NoiseLiveActivityManager {
    private static var activity: Activity<NoiseActivityAttributes>?

    static func start(title: String, remaining: Int?) {
        #if DEBUG
        print("Live Activities disabled in debug builds")
        return
        #endif
        
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { 
            print("Live Activities not enabled")
            return 
        }
        
        let attributes = NoiseActivityAttributes()
        let state = NoiseActivityAttributes.ContentState(
            title: title,
            remainingSeconds: remaining,
            isPlaying: true
        )
        
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("LiveActivity start error:", error)
        }
    }

    static func update(title: String, remaining: Int?, isPlaying: Bool) {
        #if DEBUG
        print("Live Activities disabled in debug builds")
        return
        #endif
        
        guard let activity else { 
            print("No active Live Activity to update")
            return 
        }
        
        let state = NoiseActivityAttributes.ContentState(
            title: title,
            remainingSeconds: remaining,
            isPlaying: true
        )
        
        Task { 
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    static func end() {
        #if DEBUG
        print("Live Activities disabled in debug builds")
        return
        #endif
        
        guard let activity else { 
            print("No active Live Activity to end")
            return 
        }
        
        Task { 
            await activity.end(dismissalPolicy: .immediate)
            Self.activity = nil
        }
    }
    
    static var isActive: Bool {
        #if DEBUG
        return false
        #else
        return activity != nil
        #endif
    }
}
