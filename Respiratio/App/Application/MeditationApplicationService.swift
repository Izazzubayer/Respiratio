import Foundation
import Combine

// MARK: - Application Service
/// Orchestrates meditation-related use cases and coordinates between layers
/// This service belongs to the application layer and coordinates business operations
public final class MeditationApplicationService {
    
    // MARK: - Dependencies
    private let startSessionUseCase: StartMeditationSessionUseCase
    private let completeSessionUseCase: CompleteMeditationSessionUseCase
    private let pauseSessionUseCase: PauseMeditationSessionUseCase
    private let resumeSessionUseCase: ResumeMeditationSessionUseCase
    private let getSessionUseCase: GetMeditationSessionUseCase
    private let getSessionsUseCase: GetMeditationSessionsUseCase
    private let getPresetsUseCase: GetMeditationPresetsUseCase
    private let getStatisticsUseCase: GetMeditationStatisticsUseCase
    
    // MARK: - Initialization
    public init(
        startSessionUseCase: StartMeditationSessionUseCase,
        completeSessionUseCase: CompleteMeditationSessionUseCase,
        pauseSessionUseCase: PauseMeditationSessionUseCase,
        resumeSessionUseCase: ResumeMeditationSessionUseCase,
        getSessionUseCase: GetMeditationSessionUseCase,
        getSessionsUseCase: GetMeditationSessionsUseCase,
        getPresetsUseCase: GetMeditationPresetsUseCase,
        getStatisticsUseCase: GetMeditationStatisticsUseCase
    ) {
        self.startSessionUseCase = startSessionUseCase
        self.completeSessionUseCase = completeSessionUseCase
        self.pauseSessionUseCase = pauseSessionUseCase
        self.resumeSessionUseCase = resumeSessionUseCase
        self.getSessionUseCase = getSessionUseCase
        self.getSessionsUseCase = getSessionsUseCase
        self.getPresetsUseCase = getPresetsUseCase
        self.getStatisticsUseCase = getStatisticsUseCase
    }
    
    // MARK: - Session Management
    /// Starts a new meditation session
    /// - Parameters:
    ///   - preset: The meditation preset to use
    ///   - preferences: User preferences for the session
    /// - Returns: A publisher that emits the started session or an error
    public func startSession(
        preset: MeditationPreset,
        preferences: MeditationUserPreferences
    ) -> AnyPublisher<MeditationSession, Error> {
        return startSessionUseCase.execute(preset: preset, userPreferences: preferences)
    }
    
    /// Completes an active meditation session
    /// - Parameter sessionId: The ID of the session to complete
    /// - Returns: A publisher that emits the completed session or an error
    public func completeSession(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        return completeSessionUseCase.execute(sessionId: sessionId)
    }
    
    /// Pauses an active meditation session
    /// - Parameter sessionId: The ID of the session to pause
    /// - Returns: A publisher that emits the paused session or an error
    public func pauseSession(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        return pauseSessionUseCase.execute(sessionId: sessionId)
    }
    
    /// Resumes a paused meditation session
    /// - Parameter sessionId: The ID of the session to resume
    /// - Returns: A publisher that emits the resumed session or an error
    public func resumeSession(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        return resumeSessionUseCase.execute(sessionId: sessionId)
    }
    
    // MARK: - Session Queries
    /// Retrieves a meditation session by ID
    /// - Parameter sessionId: The session ID
    /// - Returns: A publisher that emits the session or an error
    public func getSession(sessionId: UUID) -> AnyPublisher<MeditationSession?, Error> {
        return getSessionUseCase.execute(sessionId: sessionId)
    }
    
    /// Retrieves all meditation sessions
    /// - Returns: A publisher that emits an array of sessions or an error
    public func getAllSessions() -> AnyPublisher<[MeditationSession], Error> {
        return getSessionsUseCase.execute(filter: nil)
    }
    
    /// Retrieves completed meditation sessions
    /// - Returns: A publisher that emits an array of completed sessions or an error
    public func getCompletedSessions() -> AnyPublisher<[MeditationSession], Error> {
        return getSessionsUseCase.execute(filter: .completed)
    }
    
    /// Retrieves active meditation sessions
    /// - Returns: A publisher that emits an array of active sessions or an error
    public func getActiveSessions() -> AnyPublisher<[MeditationSession], Error> {
        return getSessionsUseCase.execute(filter: .active)
    }
    
    // MARK: - Preset Management
    /// Retrieves all available meditation presets
    /// - Returns: A publisher that emits an array of presets or an error
    public func getAllPresets() -> AnyPublisher<[MeditationPreset], Error> {
        return getPresetsUseCase.execute()
    }
    
    /// Retrieves presets by category
    /// - Parameter category: The meditation category
    /// - Returns: A publisher that emits an array of presets or an error
    public func getPresets(category: MeditationCategory) -> AnyPublisher<[MeditationPreset], Error> {
        return getPresetsUseCase.execute(category: category)
    }
    
    /// Retrieves presets by difficulty level
    /// - Parameter difficulty: The difficulty level
    /// - Returns: A publisher that emits an array of presets or an error
    public func getPresets(difficulty: DifficultyLevel) -> AnyPublisher<[MeditationPreset], Error> {
        return getPresetsUseCase.execute(difficulty: difficulty)
    }
    
    // MARK: - Statistics and Analytics
    /// Retrieves meditation statistics for a specific period
    /// - Parameter period: The time period for statistics
    /// - Returns: A publisher that emits statistics or an error
    public func getStatistics(for period: StatisticsPeriod) -> AnyPublisher<MeditationStatistics, Error> {
        return getStatisticsUseCase.execute(period: period)
    }
    
    /// Retrieves meditation streak information
    /// - Returns: A publisher that emits streak data or an error
    public func getStreak() -> AnyPublisher<MeditationStreak, Error> {
        return getStatisticsUseCase.execute(period: .allTime)
            .map { statistics in
                // Convert statistics to streak format
                // This is a simplified mapping - in a real app, you'd have a dedicated streak use case
                MeditationStreak(
                    currentStreak: 0, // Would be calculated from statistics
                    longestStreak: 0, // Would be calculated from statistics
                    lastCompletionDate: nil, // Would be calculated from statistics
                    totalCompletions: statistics.totalSessions
                )
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Supporting Use Cases (Placeholders)
/// These would be implemented as separate use case classes
/// For now, they're defined as protocols to show the architecture

public protocol CompleteMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error>
}

public protocol PauseMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error>
}

public protocol ResumeMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error>
}

public protocol GetMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession?, Error>
}

public protocol GetMeditationSessionsUseCase {
    func execute(filter: SessionFilter?) -> AnyPublisher<[MeditationSession], Error>
}

public protocol GetMeditationPresetsUseCase {
    func execute() -> AnyPublisher<[MeditationPreset], Error>
    func execute(category: MeditationCategory) -> AnyPublisher<[MeditationPreset], Error>
    func execute(difficulty: DifficultyLevel) -> AnyPublisher<[MeditationPreset], Error>
}

public protocol GetMeditationStatisticsUseCase {
    func execute(period: StatisticsPeriod) -> AnyPublisher<MeditationStatistics, Error>
}

// MARK: - Supporting Types
public enum SessionFilter {
    case all
    case active
    case completed
    case paused
}
