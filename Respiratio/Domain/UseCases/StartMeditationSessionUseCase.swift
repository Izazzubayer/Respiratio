import Foundation
import Combine

// MARK: - Domain Use Case
/// Business logic for starting a meditation session
/// This use case orchestrates the business rules and validation
public final class StartMeditationSessionUseCase {
    
    // MARK: - Dependencies
    private let repository: MeditationRepository
    private let audioService: AudioServiceProtocol
    private let notificationService: NotificationServiceProtocol
    
    // MARK: - Initialization
    public init(
        repository: MeditationRepository,
        audioService: AudioServiceProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.repository = repository
        self.audioService = audioService
        self.notificationService = notificationService
    }
    
    // MARK: - Public Interface
    /// Starts a new meditation session with the specified preset
    /// - Parameters:
    ///   - preset: The meditation preset to use
    ///   - userPreferences: User-specific preferences for the session
    /// - Returns: A publisher that emits the started session or an error
    public func execute(
        preset: MeditationPreset,
        userPreferences: MeditationUserPreferences
    ) -> AnyPublisher<MeditationSession, Error> {
        
        // Validate business rules
        let validationResult = validateSessionStart(preset: preset, preferences: userPreferences)
        if case .failure(let error) = validationResult {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // Create the session
        let session = createSession(preset: preset, preferences: userPreferences)
        
        // Start audio service
        let audioResult = startAudioService(preset: preset, preferences: userPreferences)
        
        // Schedule notifications
        let notificationResult = scheduleNotifications(session: session, preferences: userPreferences)
        
        // Combine all operations
        return Publishers.CombineLatest3(
            repository.createSession(session),
            audioResult,
            notificationResult
        )
        .map { createdSession, _, _ in
            createdSession
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    private func validateSessionStart(
        preset: MeditationPreset,
        preferences: MeditationUserPreferences
    ) -> Result<Void, MeditationSessionError> {
        
        // Check if user has active sessions
        // This would typically involve checking the repository
        // For now, we'll assume it's valid
        
        // Check if preset is available
        guard preset.duration > 0 else {
            return .failure(.invalidDuration)
        }
        
        // Check user preferences compatibility
        if preferences.requiresQuietEnvironment && !preferences.isQuietEnvironmentAvailable {
            return .failure(.sessionNotStarted)
        }
        
        return .success(())
    }
    
    private func createSession(
        preset: MeditationPreset,
        preferences: MeditationUserPreferences
    ) -> MeditationSession {
        
        let session = MeditationSession(
            preset: preset,
            startTime: Date(),
            endTime: nil,
            duration: 0,
            isCompleted: false,
            streakImpact: .none
        )
        
        return session
    }
    
    private func startAudioService(
        preset: MeditationPreset,
        preferences: MeditationUserPreferences
    ) -> AnyPublisher<Void, Error> {
        
        let audioConfig = AudioConfiguration(
            preset: preset,
            volume: preferences.audioVolume,
            isMuted: preferences.isAudioMuted,
            backgroundAudio: preferences.backgroundAudioEnabled
        )
        
        return audioService.startSession(config: audioConfig)
    }
    
    private func scheduleNotifications(
        session: MeditationSession,
        preferences: MeditationUserPreferences
    ) -> AnyPublisher<Void, Error> {
        
        guard preferences.notificationsEnabled else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        let notificationConfig = NotificationConfiguration(
            sessionId: session.id,
            duration: session.preset.duration,
            reminderInterval: preferences.reminderInterval,
            completionNotification: preferences.completionNotificationEnabled
        )
        
        return notificationService.scheduleNotifications(config: notificationConfig)
    }
}

// MARK: - Supporting Protocols
public protocol AudioServiceProtocol {
    func startSession(config: AudioConfiguration) -> AnyPublisher<Void, Error>
    func stopSession() -> AnyPublisher<Void, Error>
    func pauseSession() -> AnyPublisher<Void, Error>
    func resumeSession() -> AnyPublisher<Void, Error>
}

public protocol NotificationServiceProtocol {
    func scheduleNotifications(config: NotificationConfiguration) -> AnyPublisher<Void, Error>
    func cancelNotifications(for sessionId: UUID) -> AnyPublisher<Void, Error>
}

// MARK: - Configuration Types
public struct MeditationUserPreferences: Equatable {
    public let audioVolume: Double
    public let isAudioMuted: Bool
    public let backgroundAudioEnabled: Bool
    public let notificationsEnabled: Bool
    public let reminderInterval: TimeInterval
    public let completionNotificationEnabled: Bool
    public let requiresQuietEnvironment: Bool
    public let isQuietEnvironmentAvailable: Bool
    
    public init(
        audioVolume: Double = 0.7,
        isAudioMuted: Bool = false,
        backgroundAudioEnabled: Bool = true,
        notificationsEnabled: Bool = true,
        reminderInterval: TimeInterval = 300, // 5 minutes
        completionNotificationEnabled: Bool = true,
        requiresQuietEnvironment: Bool = false,
        isQuietEnvironmentAvailable: Bool = true
    ) {
        self.audioVolume = audioVolume
        self.isAudioMuted = isAudioMuted
        self.backgroundAudioEnabled = backgroundAudioEnabled
        self.notificationsEnabled = notificationsEnabled
        self.reminderInterval = reminderInterval
        self.completionNotificationEnabled = completionNotificationEnabled
        self.requiresQuietEnvironment = requiresQuietEnvironment
        self.isQuietEnvironmentAvailable = isQuietEnvironmentAvailable
    }
}

public struct AudioConfiguration: Equatable {
    public let preset: MeditationPreset
    public let volume: Double
    public let isMuted: Bool
    public let backgroundAudio: Bool
    
    public init(
        preset: MeditationPreset,
        volume: Double,
        isMuted: Bool,
        backgroundAudio: Bool
    ) {
        self.preset = preset
        self.volume = volume
        self.isMuted = isMuted
        self.backgroundAudio = backgroundAudio
    }
}

public struct NotificationConfiguration: Equatable {
    public let sessionId: UUID
    public let duration: TimeInterval
    public let reminderInterval: TimeInterval
    public let completionNotification: Bool
    
    public init(
        sessionId: UUID,
        duration: TimeInterval,
        reminderInterval: TimeInterval,
        completionNotification: Bool
    ) {
        self.sessionId = sessionId
        self.duration = duration
        self.reminderInterval = reminderInterval
        self.completionNotification = completionNotification
    }
}
