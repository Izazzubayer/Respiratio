import Foundation
import Combine

// MARK: - Dependency Injection Container
/// Centralized dependency injection container
/// This follows the Service Locator pattern for enterprise applications
public final class DependencyContainer {
    
    // MARK: - Singleton
    public static let shared = DependencyContainer()
    
    // MARK: - Private Properties
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    // MARK: - Initialization
    private init() {
        registerDefaultServices()
    }
    
    // MARK: - Service Registration
    /// Registers a service instance
    /// - Parameters:
    ///   - service: The service instance to register
    ///   - type: The type to register the service as
    public func register<T>(_ service: T, as type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }
    
    /// Registers a service factory
    /// - Parameters:
    ///   - factory: The factory closure that creates the service
    ///   - type: The type to register the service as
    public func register<T>(_ factory: @escaping () -> T, as type: T.Type) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    /// Registers a service with a custom key
    /// - Parameters:
    ///   - service: The service instance to register
    ///   - key: The custom key for the service
    public func register<T>(_ service: T, withKey key: String) {
        services[key] = service
    }
    
    // MARK: - Service Resolution
    /// Resolves a service of the specified type
    /// - Parameter type: The type of service to resolve
    /// - Returns: The resolved service instance
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check if we have a cached instance
        if let service = services[key] as? T {
            return service
        }
        
        // Check if we have a factory
        if let factory = factories[key] {
            let service = factory()
            services[key] = service
            return service as! T
        }
        
        fatalError("Service of type \(T.self) not registered")
    }
    
    /// Resolves a service with a custom key
    /// - Parameters:
    ///   - type: The type of service to resolve
    ///   - key: The custom key for the service
    /// - Returns: The resolved service instance
    public func resolve<T>(_ type: T.Type, withKey key: String) -> T {
        if let service = services[key] as? T {
            return service
        }
        
        fatalError("Service of type \(T.self) with key \(key) not registered")
    }
    
    /// Safely resolves a service, returning nil if not found
    /// - Parameter type: The type of service to resolve
    /// - Returns: The resolved service instance or nil
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        if let factory = factories[key] {
            let service = factory()
            services[key] = service
            return service as? T
        }
        
        return nil
    }
    
    // MARK: - Service Removal
    /// Removes a registered service
    /// - Parameter type: The type of service to remove
    public func remove<T>(_ type: T.Type) {
        let key = String(describing: type)
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
    }
    
    /// Removes a service with a custom key
    /// - Parameter key: The custom key of the service to remove
    public func remove(withKey key: String) {
        services.removeValue(forKey: key)
        factories.removeValue(forKey: key)
    }
    
    /// Clears all registered services
    public func clear() {
        services.removeAll()
        factories.removeAll()
    }
    
    // MARK: - Private Methods
    private func registerDefaultServices() {
        // Register core services
        registerDefaultStorageServices()
        registerDefaultNetworkServices()
        registerDefaultAudioServices()
        registerDefaultHapticServices()
        registerDefaultAnalyticsServices()
        registerDefaultCacheServices()
        registerDefaultNotificationServices()
        registerDefaultUserServices()
        registerDefaultRepositoryServices()
        registerDefaultUseCaseServices()
        registerDefaultApplicationServices()
    }
    
    private func registerDefaultStorageServices() {
        // Local storage service
        register(LocalStorageService(), as: StorageServiceProtocol.self)
    }
    
    private func registerDefaultNetworkServices() {
        // Network service
        register(NetworkService(), as: NetworkServiceProtocol.self)
    }
    
    private func registerDefaultAudioServices() {
        // Audio service
        register(AudioService(), as: AudioServiceProtocol.self)
    }
    
    private func registerDefaultHapticServices() {
        // Haptic service
        register(HapticService(), as: HapticServiceProtocol.self)
    }
    
    private func registerDefaultAnalyticsServices() {
        // Analytics service
        register(AnalyticsService(), as: AnalyticsServiceProtocol.self)
    }
    
    private func registerDefaultCacheServices() {
        // Cache service
        register(CacheService(), as: CacheServiceProtocol.self)
    }
    
    private func registerDefaultNotificationServices() {
        // Notification service
        register(NotificationService(), as: NotificationServiceProtocol.self)
    }
    
    private func registerDefaultUserServices() {
        // User service
        register(MockUserService(), as: UserServiceProtocol.self)
        // Onboarding service
        register(MockOnboardingService(), as: OnboardingServiceProtocol.self)
    }
    
    private func registerDefaultRepositoryServices() {
        // Meditation repository
        let meditationRepository = MeditationRepositoryImpl(
            storageService: resolve(StorageServiceProtocol.self),
            networkService: resolve(NetworkServiceProtocol.self),
            cacheService: resolve(CacheServiceProtocol.self),
            analyticsService: resolve(AnalyticsServiceProtocol.self)
        )
        register(meditationRepository, as: MeditationRepository.self)
    }
    
    private func registerDefaultUseCaseServices() {
        // Start meditation session use case
        let startSessionUseCase = StartMeditationSessionUseCase(
            repository: resolve(MeditationRepository.self),
            audioService: resolve(AudioServiceProtocol.self),
            notificationService: resolve(NotificationServiceProtocol.self)
        )
        register(startSessionUseCase, as: StartMeditationSessionUseCase.self)
        
        // Other use cases would be registered here
        // For now, we'll create mock implementations
        register(MockCompleteMeditationSessionUseCase(), as: CompleteMeditationSessionUseCase.self)
        register(MockPauseMeditationSessionUseCase(), as: PauseMeditationSessionUseCase.self)
        register(MockResumeMeditationSessionUseCase(), as: ResumeMeditationSessionUseCase.self)
        register(MockGetMeditationSessionUseCase(), as: GetMeditationSessionUseCase.self)
        register(MockGetMeditationSessionsUseCase(), as: GetMeditationSessionsUseCase.self)
        register(MockGetMeditationPresetsUseCase(), as: GetMeditationPresetsUseCase.self)
        register(MockGetMeditationStatisticsUseCase(), as: GetMeditationStatisticsUseCase.self)
    }
    
    private func registerDefaultApplicationServices() {
        // Meditation application service
        let meditationAppService = MeditationApplicationService(
            startSessionUseCase: resolve(StartMeditationSessionUseCase.self),
            completeSessionUseCase: resolve(CompleteMeditationSessionUseCase.self),
            pauseSessionUseCase: resolve(PauseMeditationSessionUseCase.self),
            resumeSessionUseCase: resolve(ResumeMeditationSessionUseCase.self),
            getSessionUseCase: resolve(GetMeditationSessionUseCase.self),
            getSessionsUseCase: resolve(GetMeditationSessionsUseCase.self),
            getPresetsUseCase: resolve(GetMeditationPresetsUseCase.self),
            getStatisticsUseCase: resolve(GetMeditationStatisticsUseCase.self)
        )
        register(meditationAppService, as: MeditationApplicationService.self)
    }
}

// MARK: - Mock Implementations
/// These are temporary mock implementations for the use cases
/// In a real application, these would be proper implementations

private final class MockCompleteMeditationSessionUseCase: CompleteMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Fail(error: NSError(domain: "Mock", code: 0, userInfo: nil)).eraseToAnyPublisher()
    }
}

private final class MockPauseMeditationSessionUseCase: PauseMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Fail(error: NSError(domain: "Mock", code: 0, userInfo: nil)).eraseToAnyPublisher()
    }
}

private final class MockResumeMeditationSessionUseCase: ResumeMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Fail(error: NSError(domain: "Mock", code: 0, userInfo: nil)).eraseToAnyPublisher()
    }
}

private final class MockGetMeditationSessionUseCase: GetMeditationSessionUseCase {
    func execute(sessionId: UUID) -> AnyPublisher<MeditationSession?, Error> {
        // Mock implementation
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class MockGetMeditationSessionsUseCase: GetMeditationSessionsUseCase {
    func execute(filter: SessionFilter?) -> AnyPublisher<[MeditationSession], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class MockGetMeditationPresetsUseCase: GetMeditationPresetsUseCase {
    func execute() -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func execute(category: MeditationCategory) -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func execute(difficulty: DifficultyLevel) -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class MockGetMeditationStatisticsUseCase: GetMeditationStatisticsUseCase {
    func execute(period: StatisticsPeriod) -> AnyPublisher<MeditationStatistics, Error> {
        // Mock implementation
        return Just(MeditationStatistics(period: period)).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

// MARK: - Service Implementations
/// These are basic service implementations
/// In a real application, these would be more sophisticated

private final class LocalStorageService: StorageServiceProtocol {
    func saveSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getSession(id: UUID) -> AnyPublisher<MeditationSession?, Error> {
        // Mock implementation
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func updateSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func deleteSession(id: UUID) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getAllSessions() -> AnyPublisher<[MeditationSession], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getAllPresets() -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class NetworkService: NetworkServiceProtocol {
    func syncSession(_ session: MeditationSession) -> AnyPublisher<MeditationSession, Error> {
        // Mock implementation
        return Just(session).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchSession(id: UUID) -> AnyPublisher<MeditationSession?, Error> {
        // Mock implementation
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func deleteSession(id: UUID) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchAllSessions() -> AnyPublisher<[MeditationSession], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchAllPresets() -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class AudioService: AudioServiceProtocol {
    func startSession(config: AudioConfiguration) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func stopSession() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func pauseSession() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func resumeSession() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class HapticService: HapticServiceProtocol {
    func trigger(_ feedback: HapticFeedback) {
        // Mock implementation
        print("Haptic feedback triggered: \(feedback)")
    }
}

private final class AnalyticsService: AnalyticsServiceProtocol {
    func logEvent(_ event: String, properties: [String: Any]) {
        // Mock implementation
        print("Analytics event: \(event) with properties: \(properties)")
    }
    
    func logError(_ error: Error, context: String) {
        // Mock implementation
        print("Analytics error in \(context): \(error.localizedDescription)")
    }
}

private final class CacheService: CacheServiceProtocol {
    func cacheSession(_ session: MeditationSession) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getCachedSession(id: UUID) -> AnyPublisher<MeditationSession?, Error> {
        // Mock implementation
        return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func removeCachedSession(id: UUID) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getAllCachedSessions() -> AnyPublisher<[MeditationSession], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func getAllCachedPresets() -> AnyPublisher<[MeditationPreset], Error> {
        // Mock implementation
        return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class NotificationService: NotificationServiceProtocol {
    func scheduleNotifications(config: NotificationConfiguration) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func cancelNotifications(for sessionId: UUID) -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class MockUserService: UserServiceProtocol {
    func getCurrentUser() -> AnyPublisher<User?, Error> {
        // Mock implementation - return a sample user
        let user = User(
            name: "Sample User",
            email: "user@example.com"
        )
        return Just(user).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func signOut() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

private final class MockOnboardingService: OnboardingServiceProtocol {
    func isOnboardingComplete() -> Bool {
        // Mock implementation - always return false for first launch
        return false
    }
    
    func markOnboardingComplete() -> AnyPublisher<Void, Error> {
        // Mock implementation
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
