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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
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
        guard let activity else { return }
        let state = NoiseActivityAttributes.ContentState(
            title: title,
            remainingSeconds: remaining,
            isPlaying: isPlaying
        )
        Task { await activity.update(.init(state: state, staleDate: nil)) }
    }

    static func end() {
        guard let activity else { return }
        Task { await activity.end(dismissalPolicy: .immediate) }
        Self.activity = nil
    }
}
