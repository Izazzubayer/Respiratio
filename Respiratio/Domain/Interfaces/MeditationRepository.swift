import Foundation
import Combine

// MARK: - Domain Repository Interface
/// Defines the contract for meditation data operations
/// This interface belongs to the domain layer and has no implementation details
public protocol MeditationRepository {
    
    // MARK: - Session Management
    /// Creates a new meditation session
    /// - Parameter session: The session to create
    /// - Returns: A publisher that emits the created session or an error
    func createSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error>
    
    /// Retrieves a meditation session by ID
    /// - Parameter id: The session ID
    /// - Returns: A publisher that emits the session or an error
    func getSession(id: UUID) -> AnyPublisher<MeditationSession?, Error>
    
    /// Updates an existing meditation session
    /// - Parameter session: The session to update
    /// - Returns: A publisher that emits the updated session or an error
    func updateSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error>
    
    /// Deletes a meditation session
    /// - Parameter id: The session ID to delete
    /// - Returns: A publisher that emits success or an error
    func deleteSession(id: UUID) -> AnyPublisher<Void, Error>
    
    // MARK: - Session Queries
    /// Retrieves all meditation sessions for a user
    /// - Returns: A publisher that emits an array of sessions or an error
    func getAllSessions() -> AnyPublisher<[MeditationSession], Error>
    
    /// Retrieves completed meditation sessions
    /// - Returns: A publisher that emits an array of completed sessions or an error
    func getCompletedSessions() -> AnyPublisher<[MeditationSession], Error>
    
    /// Retrieves active meditation sessions
    /// - Returns: A publisher that emits an array of active sessions or an error
    func getActiveSessions() -> AnyPublisher<[MeditationSession], Error>
    
    /// Retrieves sessions within a date range
    /// - Parameters:
    ///   - startDate: The start date for the range
    ///   - endDate: The end date for the range
    /// - Returns: A publisher that emits an array of sessions or an error
    func getSessions(from startDate: Date, to endDate: Date) -> AnyPublisher<[MeditationSession], Error>
    
    // MARK: - Preset Management
    /// Retrieves all available meditation presets
    /// - Returns: A publisher that emits an array of presets or an error
    func getAllPresets() -> AnyPublisher<[MeditationPreset], Error>
    
    /// Retrieves presets by category
    /// - Parameter category: The meditation category
    /// - Returns: A publisher that emits an array of presets or an error
    func getPresets(category: MeditationCategory) -> AnyPublisher<[MeditationPreset], Error>
    
    /// Retrieves presets by difficulty level
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A publisher that emits an array of presets or an error
    func getPresets(difficulty: DifficultyLevel) -> AnyPublisher<[MeditationPreset], Error>
    
    /// Retrieves a preset by ID
    /// - Parameter id: The preset ID
    /// - Returns: A publisher that emits the preset or an error
    func getPreset(id: UUID) -> AnyPublisher<MeditationPreset?, Error>
    
    // MARK: - Statistics and Analytics
    /// Retrieves total meditation time for a user
    /// - Returns: A publisher that emits the total time or an error
    func getTotalMeditationTime() -> AnyPublisher<TimeInterval, Error>
    
    /// Retrieves meditation streak information
    /// - Returns: A publisher that emits streak data or an error
    func getMeditationStreak() -> AnyPublisher<MeditationStreak, Error>
    
    /// Retrieves meditation statistics for a specific period
    /// - Parameter period: The time period for statistics
    /// - Returns: A publisher that emits statistics or an error
    func getMeditationStatistics(for period: StatisticsPeriod) -> AnyPublisher<MeditationStatistics, Error>
}

// MARK: - Supporting Types
public struct MeditationStreak: Equatable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastCompletionDate: Date?
    public let totalCompletions: Int
    
    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastCompletionDate: Date? = nil,
        totalCompletions: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastCompletionDate = lastCompletionDate
        self.totalCompletions = totalCompletions
    }
}

public enum StatisticsPeriod: CaseIterable {
    case today
    case week
    case month
    case year
    case allTime
}

public struct MeditationStatistics: Equatable {
    public let period: StatisticsPeriod
    public let totalSessions: Int
    public let totalDuration: TimeInterval
    public let averageSessionDuration: TimeInterval
    public let mostUsedPreset: MeditationPreset?
    public let completionRate: Double
    
    public init(
        period: StatisticsPeriod,
        totalSessions: Int = 0,
        totalDuration: TimeInterval = 0,
        averageSessionDuration: TimeInterval = 0,
        mostUsedPreset: MeditationPreset? = nil,
        completionRate: Double = 0
    ) {
        self.period = period
        self.totalSessions = totalSessions
        self.totalDuration = totalDuration
        self.averageSessionDuration = averageSessionDuration
        self.mostUsedPreset = mostUsedPreset
        self.completionRate = completionRate
    }
}

// MARK: - Repository Errors
public enum MeditationRepositoryError: LocalizedError, Equatable {
    case sessionNotFound
    case presetNotFound
    case invalidData
    case networkError
    case storageError
    case unauthorized
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound:
            return "Meditation session not found"
        case .presetNotFound:
            return "Meditation preset not found"
        case .invalidData:
            return "Invalid data provided"
        case .networkError:
            return "Network connection error"
        case .storageError:
            return "Data storage error"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}
