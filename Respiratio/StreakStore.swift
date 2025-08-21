//
//  StreakStore.swift
//  Respiratio
//
//  Created by Izzy Drizzy on 2025-08-21.
//

import Foundation
import SwiftUI

/// Simple persistent streak tracker using @AppStorage.
/// Rules:
/// - Completing multiple sessions in one day does NOT increment the streak again.
/// - Completing on consecutive days increments streak.
/// - Missed day resets streak to 1 on the next completion.
final class StreakStore: ObservableObject {
    @AppStorage("meditationStreak") private var streakStorage: Int = 0
    @AppStorage("bestMeditationStreak") private var bestStreakStorage: Int = 0
    @AppStorage("lastMeditationDate") private var lastDateStorage: Double = 0 // timeIntervalSince1970

    @Published private(set) var streak: Int = 0
    @Published private(set) var bestStreak: Int = 0
    @Published private(set) var lastCompletionDate: Date? = nil

    private let cal = Calendar.current

    init() {
        self.streak = streakStorage
        self.bestStreak = bestStreakStorage
        self.lastCompletionDate = lastDateStorage == 0 ? nil : Date(timeIntervalSince1970: lastDateStorage)
    }

    /// Call this when a session completes. Returns whether the streak increased or reset.
    @discardableResult
    func registerCompletion(on date: Date = Date()) -> (didIncrement: Bool, didReset: Bool) {
        var didIncrement = false
        var didReset = false

        let today = cal.startOfDay(for: date)
        let last = lastCompletionDate.map { cal.startOfDay(for: $0) }

        switch last {
        case .some(let lastDay):
            if cal.isDate(today, inSameDayAs: lastDay) {
                // same day: no change
            } else if let yday = cal.date(byAdding: .day, value: 1, to: lastDay), cal.isDate(today, inSameDayAs: yday) {
                streak += 1
                didIncrement = true
            } else {
                streak = 1
                didReset = true
            }
        case .none:
            streak = 1
            didIncrement = true
        }

        bestStreak = max(bestStreak, streak)
        lastCompletionDate = today

        // Persist
        streakStorage = streak
        bestStreakStorage = bestStreak
        lastDateStorage = today.timeIntervalSince1970

        objectWillChange.send()
        return (didIncrement, didReset)
    }
}
