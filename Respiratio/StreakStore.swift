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

    private let calendar = Calendar.current

    init() {
        self.streak = max(0, streakStorage)
        self.bestStreak = max(0, bestStreakStorage)
        self.lastCompletionDate = lastDateStorage == 0 ? nil : Date(timeIntervalSince1970: lastDateStorage)
    }

    /// Call this when a session completes. Returns whether the streak increased or reset.
    @discardableResult
    func registerCompletion(on date: Date = Date()) -> (didIncrement: Bool, didReset: Bool) {
        var didIncrement = false
        var didReset = false

        let today = calendar.startOfDay(for: date)
        let last = lastCompletionDate.map { calendar.startOfDay(for: $0) }

        switch last {
        case .some(let lastDay):
            if calendar.isDate(today, inSameDayAs: lastDay) {
                // same day: no change
            } else if let yday = calendar.date(byAdding: .day, value: 1, to: lastDay), 
                      calendar.isDate(today, inSameDayAs: yday) {
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

        // Persist with validation
        streakStorage = max(0, streak)
        bestStreakStorage = max(0, bestStreak)
        lastDateStorage = today.timeIntervalSince1970

        objectWillChange.send()
        return (didIncrement, didReset)
    }
    
    /// Reset streak data (useful for testing or user preference)
    func resetStreak() {
        streak = 0
        bestStreak = 0
        lastCompletionDate = nil
        streakStorage = 0
        bestStreakStorage = 0
        lastDateStorage = 0
        objectWillChange.send()
    }
}
