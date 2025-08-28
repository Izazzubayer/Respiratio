import Foundation

// MARK: - Core Domain Entity
/// Represents a meditation session in the domain layer
/// This is a pure business object with no framework dependencies
public struct MeditationSession: Identifiable, Equatable {
    
    // MARK: - Properties
    public let id: UUID
    public let preset: MeditationPreset
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval
    public let isCompleted: Bool
    public let streakImpact: StreakImpact
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        preset: MeditationPreset,
        startTime: Date = Date(),
        endTime: Date? = nil,
        duration: TimeInterval = 0,
        isCompleted: Bool = false,
        streakImpact: StreakImpact = .none
    ) {
        self.id = id
        self.preset = preset
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.isCompleted = isCompleted
        self.streakImpact = streakImpact
    }
    
    // MARK: - Computed Properties
    public var sessionDuration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    public var isActive: Bool {
        return !isCompleted && endTime == nil
    }
    
    public var progressPercentage: Double {
        guard preset.duration > 0 else { return 0 }
        return min(sessionDuration / preset.duration, 1.0)
    }
}

// MARK: - Value Objects
public struct MeditationPreset: Identifiable, Equatable {
    public let id: UUID
    public let title: String
    public let description: String
    public let duration: TimeInterval
    public let category: MeditationCategory
    public let difficulty: DifficultyLevel
    public let symbol: String
    public let audioFileName: String?
    public let hasAudio: Bool
    public let tags: [String]
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        duration: TimeInterval,
        category: MeditationCategory,
        difficulty: DifficultyLevel,
        symbol: String = "timer",
        audioFileName: String? = nil,
        hasAudio: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
        self.category = category
        self.difficulty = difficulty
        self.symbol = symbol
        self.audioFileName = audioFileName
        self.hasAudio = hasAudio
        self.tags = tags
    }
}

public enum MeditationCategory: String, CaseIterable {
    case mindfulness = "mindfulness"
    case breathing = "breathing"
    case relaxation = "relaxation"
    case focus = "focus"
    case sleep = "sleep"
    case stress = "stress"
}

public enum DifficultyLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}

public enum StreakImpact: Equatable {
    case none
    case maintained
    case increased
    case broken
}

// MARK: - Domain Errors
public enum MeditationSessionError: LocalizedError {
    case invalidDuration
    case sessionAlreadyCompleted
    case sessionNotStarted
    case presetNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidDuration:
            return "Invalid session duration"
        case .sessionAlreadyCompleted:
            return "Session is already completed"
        case .sessionNotStarted:
            return "Session has not started"
        case .presetNotFound:
            return "Meditation preset not found"
        }
    }
}

// MARK: - Domain Validation
extension MeditationSession {
    public func validate() -> Result<Void, MeditationSessionError> {
        if duration < 0 {
            return .failure(.invalidDuration)
        }
        
        if isCompleted && endTime == nil {
            return .failure(.sessionAlreadyCompleted)
        }
        
        return .success(())
    }
    
    public func canComplete() -> Bool {
        return isActive && sessionDuration >= preset.duration
    }
}

// MARK: - Domain Operations
extension MeditationSession {
    public func complete() -> MeditationSession {
        guard canComplete() else {
            return self
        }
        
        return MeditationSession(
            id: id,
            preset: preset,
            startTime: startTime,
            endTime: Date(),
            duration: sessionDuration,
            isCompleted: true,
            streakImpact: .increased
        )
    }
    
    public func pause() -> MeditationSession {
        guard isActive else { return self }
        
        return MeditationSession(
            id: id,
            preset: preset,
            startTime: startTime,
            endTime: Date(),
            duration: sessionDuration,
            isCompleted: false,
            streakImpact: streakImpact
        )
    }
    
    public func resume() -> MeditationSession {
        guard !isActive && !isCompleted else { return self }
        
        return MeditationSession(
            id: id,
            preset: preset,
            startTime: Date(),
            endTime: nil,
            duration: duration,
            isCompleted: false,
            streakImpact: streakImpact
        )
    }
}
