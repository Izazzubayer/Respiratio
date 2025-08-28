import Foundation
import Combine

// MARK: - Infrastructure Repository Implementation
/// Concrete implementation of the meditation repository
/// This belongs to the infrastructure layer and handles data persistence
public final class MeditationRepositoryImpl: MeditationRepository {
    
    // MARK: - Dependencies
    private let storageService: StorageServiceProtocol
    private let networkService: NetworkServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(
        storageService: StorageServiceProtocol,
        networkService: NetworkServiceProtocol,
        cacheService: CacheServiceProtocol,
        analyticsService: AnalyticsServiceProtocol
    ) {
        self.storageService = storageService
        self.networkService = networkService
        self.cacheService = cacheService
        self.analyticsService = analyticsService
    }
    
    // MARK: - Session Management
    public func createSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error> {
        // Validate the session
        let validationResult = session.validate()
        if case .failure(let error) = validationResult {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Store locally first for immediate availability
        let localStorage = storageService.saveSession(session)
        
        // Attempt to sync with remote server
        let remoteSync = networkService.syncSession(session)
            .catch { error -> AnyPublisher<MeditationSession, Error> in
                // If remote sync fails, log the error but don't fail the operation
                self.analyticsService.logError(error, context: "remote_sync_failed")
                return Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Cache the session for quick access
        let cacheStorage = cacheService.cacheSession(session)
        
        // Combine all operations
        return Publishers.CombineLatest3(localStorage, remoteSync, cacheStorage)
            .map { _, _, _ in session }
            .handleEvents(
                receiveOutput: { [weak self] session in
                    self?.analyticsService.logEvent("session_created", properties: [
                        "session_id": session.id.uuidString,
                        "preset_title": session.preset.title,
                        "duration": session.preset.duration
                    ])
                }
            )
            .eraseToAnyPublisher()
    }
    
    public func getSession(id: UUID) -> AnyPublisher<MeditationSession?, Error> {
        // Try cache first for fastest response
        let cachedSession = cacheService.getCachedSession(id: id)
        
        // Fall back to local storage
        let localSession = storageService.getSession(id: id)
        
        // Combine with remote fetch for latest data
        let remoteSession = networkService.fetchSession(id: id)
            .catch { error -> AnyPublisher<MeditationSession?, Error> in
                // If remote fetch fails, continue with local data
                self.analyticsService.logError(error, context: "remote_fetch_failed")
                return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Return the first available result
        return Publishers.MergeMany([cachedSession, localSession, remoteSession])
            .first { $0 != nil }
            .eraseToAnyPublisher()
    }
    
    public func updateSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error> {
        // Validate the session
        let validationResult = session.validate()
        if case .failure(let error) = validationResult {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Update local storage
        let localUpdate = storageService.updateSession(session)
        
        // Update cache
        let cacheUpdate = cacheService.cacheSession(session)
        
        // Sync with remote server
        let remoteUpdate = networkService.syncSession(session)
            .catch { error -> AnyPublisher<MeditationSession, Error> in
                // If remote update fails, log the error but don't fail the operation
                self.analyticsService.logError(error, context: "remote_update_failed")
                return Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Combine all operations
        return Publishers.CombineLatest3(localUpdate, cacheUpdate, remoteUpdate)
            .map { _, _, _ in session }
            .handleEvents(
                receiveOutput: { [weak self] session in
                    self?.analyticsService.logEvent("session_updated", properties: [
                        "session_id": session.id.uuidString,
                        "is_completed": session.isCompleted
                    ])
                }
            )
            .eraseToAnyPublisher()
    }
    
    public func deleteSession(id: UUID) -> AnyPublisher<Void, Error> {
        // Remove from local storage
        let localDelete = storageService.deleteSession(id: id)
        
        // Remove from cache
        let cacheDelete = cacheService.removeCachedSession(id: id)
        
        // Remove from remote server
        let remoteDelete = networkService.deleteSession(id: id)
            .catch { error -> AnyPublisher<Void, Error> in
                // If remote delete fails, log the error but don't fail the operation
                self.analyticsService.logError(error, context: "remote_delete_failed")
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Combine all operations
        return Publishers.CombineLatest3(localDelete, cacheDelete, remoteDelete)
            .map { _, _, _ in () }
            .handleEvents(
                receiveOutput: { [weak self] _ in
                    self?.analyticsService.logEvent("session_deleted", properties: [
                        "session_id": id.uuidString
                    ])
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Session Queries
    public func getAllSessions() -> AnyPublisher<[MeditationSession], Error> {
        // Try cache first
        let cachedSessions = cacheService.getAllCachedSessions()
        
        // Fall back to local storage
        let localSessions = storageService.getAllSessions()
        
        // Combine with remote fetch
        let remoteSessions = networkService.fetchAllSessions()
            .catch { error -> AnyPublisher<[MeditationSession], Error> in
                self.analyticsService.logError(error, context: "remote_fetch_all_failed")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Return the first available result
        return Publishers.MergeMany([cachedSessions, localSessions, remoteSessions])
            .first { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    public func getCompletedSessions() -> AnyPublisher<[MeditationSession], Error> {
        return getAllSessions()
            .map { sessions in
                sessions.filter { $0.isCompleted }
            }
            .eraseToAnyPublisher()
    }
    
    public func getActiveSessions() -> AnyPublisher<[MeditationSession], Error> {
        return getAllSessions()
            .map { sessions in
                sessions.filter { $0.isActive }
            }
            .eraseToAnyPublisher()
    }
    
    public func getSessions(from startDate: Date, to endDate: Date) -> AnyPublisher<[MeditationSession], Error> {
        return getAllSessions()
            .map { sessions in
                sessions.filter { session in
                    session.startTime >= startDate && session.startTime <= endDate
                }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Preset Management
    public func getAllPresets() -> AnyPublisher<[MeditationPreset], Error> {
        // Try cache first
        let cachedPresets = cacheService.getAllCachedPresets()
        
        // Fall back to local storage
        let localPresets = storageService.getAllPresets()
        
        // Combine with remote fetch
        let remotePresets = networkService.fetchAllPresets()
            .catch { error -> AnyPublisher<[MeditationPreset], Error> in
                self.analyticsService.logError(error, context: "remote_fetch_presets_failed")
                return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
        
        // Return the first available result
        return Publishers.MergeMany([cachedPresets, localPresets, remotePresets])
            .first { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
    
    public func getPresets(category: MeditationCategory) -> AnyPublisher<[MeditationPreset], Error> {
        return getAllPresets()
            .map { presets in
                presets.filter { $0.category == category }
            }
            .eraseToAnyPublisher()
    }
    
    public func getPresets(difficulty: DifficultyLevel) -> AnyPublisher<[MeditationPreset], Error> {
        return getAllPresets()
            .map { presets in
                presets.filter { $0.difficulty == difficulty }
            }
            .eraseToAnyPublisher()
    }
    
    public func getPreset(id: UUID) -> AnyPublisher<MeditationPreset?, Error> {
        return getAllPresets()
            .map { presets in
                presets.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Statistics and Analytics
    public func getTotalMeditationTime() -> AnyPublisher<TimeInterval, Error> {
        return getCompletedSessions()
            .map { sessions in
                sessions.reduce(0) { total, session in
                    total + session.sessionDuration
                }
            }
            .eraseToAnyPublisher()
    }
    
    public func getMeditationStreak() -> AnyPublisher<MeditationStreak, Error> {
        return getCompletedSessions()
            .map { sessions in
                self.calculateStreak(from: sessions)
            }
            .eraseToAnyPublisher()
    }
    
    public func getMeditationStatistics(for period: StatisticsPeriod) -> AnyPublisher<MeditationStatistics, Error> {
        return getCompletedSessions()
            .map { sessions in
                self.calculateStatistics(from: sessions, for: period)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    private func calculateStreak(from sessions: [MeditationSession]) -> MeditationStreak {
        let calendar = Calendar.current
        // Sort sessions by completion date (most recent first)
        let sortedSessions = sessions.sorted { $0.startTime > $1.startTime }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        var lastDate: Date?
        
        for session in sortedSessions {
            guard let endTime = session.endTime else { continue }
            
            let sessionDate = calendar.startOfDay(for: endTime)
            
            if let last = lastDate {
                let lastDay = calendar.startOfDay(for: last)
                let daysDifference = calendar.dateComponents([.day], from: sessionDate, to: lastDay).day ?? 0
                
                if daysDifference == 1 {
                    // Consecutive day
                    tempStreak += 1
                } else if daysDifference > 1 {
                    // Streak broken
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                // First session
                tempStreak = 1
            }
            
            lastDate = sessionDate
        }
        
        // Check if today's session exists
        let today = Date()
        let todayStart = calendar.startOfDay(for: today)
        let hasTodaySession = sortedSessions.contains { session in
            guard let endTime = session.endTime else { return false }
            return calendar.isDate(endTime, inSameDayAs: today)
        }
        
        if hasTodaySession {
            currentStreak = tempStreak
        } else {
            currentStreak = 0
        }
        
        longestStreak = max(longestStreak, tempStreak)
        
        return MeditationStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletionDate: sortedSessions.first?.endTime,
            totalCompletions: sessions.count
        )
    }
    
    private func calculateStatistics(from sessions: [MeditationSession], for period: StatisticsPeriod) -> MeditationStatistics {
        let calendar = Calendar.current
        let now = Date()
        
        let filteredSessions: [MeditationSession]
        
        switch period {
        case .today:
            let todayStart = calendar.startOfDay(for: now)
            filteredSessions = sessions.filter { session in
                guard let endTime = session.endTime else { return false }
                return endTime >= todayStart
            }
        case .week:
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            filteredSessions = sessions.filter { session in
                guard let endTime = session.endTime else { return false }
                return endTime >= weekStart
            }
        case .month:
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            filteredSessions = sessions.filter { session in
                guard let endTime = session.endTime else { return false }
                return endTime >= monthStart
            }
        case .year:
            let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
            filteredSessions = sessions.filter { session in
                guard let endTime = session.endTime else { return false }
                return endTime >= yearStart
            }
        case .allTime:
            filteredSessions = sessions
        }
        
        let totalSessions = filteredSessions.count
        let totalDuration = filteredSessions.reduce(0) { $0 + $1.sessionDuration }
        let averageSessionDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        
        // Find most used preset
        let presetCounts = Dictionary(grouping: filteredSessions, by: { $0.preset.id })
            .mapValues { $0.count }
        let mostUsedPresetId = presetCounts.max(by: { $0.value < $1.value })?.key
        let mostUsedPreset = mostUsedPresetId.flatMap { id in
            filteredSessions.first { $0.preset.id == id }?.preset
        }
        
        let completionRate = totalSessions > 0 ? 1.0 : 0.0 // All sessions are completed by definition
        
        return MeditationStatistics(
            period: period,
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageSessionDuration: averageSessionDuration,
            mostUsedPreset: mostUsedPreset,
            completionRate: completionRate
        )
    }
}

// MARK: - Supporting Protocols
public protocol StorageServiceProtocol {
    func saveSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error>
    func getSession(id: UUID) -> AnyPublisher<MeditationSession?, Error>
    func updateSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error>
    func deleteSession(id: UUID) -> AnyPublisher<Void, Error>
    func getAllSessions() -> AnyPublisher<[MeditationSession], Error>
    func getAllPresets() -> AnyPublisher<[MeditationPreset], Error>
}

public protocol NetworkServiceProtocol {
    func syncSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error>
    func fetchSession(id: UUID) -> AnyPublisher<MeditationSession?, Error>
    func deleteSession(id: UUID) -> AnyPublisher<Void, Error>
    func fetchAllSessions() -> AnyPublisher<[MeditationSession], Error>
    func fetchAllPresets() -> AnyPublisher<[MeditationPreset], Error>
}

public protocol CacheServiceProtocol {
    func cacheSession(_ session: MeditationSession) -> AnyPublisher<Void, Error>
    func getCachedSession(id: UUID) -> AnyPublisher<MeditationSession?, Error>
    func removeCachedSession(id: UUID) -> AnyPublisher<Void, Error>
    func getAllCachedSessions() -> AnyPublisher<[MeditationSession], Error>
    func getAllCachedPresets() -> AnyPublisher<[MeditationPreset], Error>
}

public protocol AnalyticsServiceProtocol {
    func logEvent(_ event: String, properties: [String: Any])
    func logError(_ error: Error, context: String)
}
