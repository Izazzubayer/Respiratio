import SwiftUI
import Combine

// MARK: - App Entry Point
/// Main application entry point using enterprise architecture
@main
public struct RespiratioApp: App {
    
    // MARK: - Properties
    @StateObject private var appCoordinator: AppCoordinator
    
    // MARK: - Initialization
    public init() {
        // Initialize dependency container
        _ = DependencyContainer.shared
        
        // Create app coordinator
        let coordinator = AppCoordinator()
        _appCoordinator = StateObject(wrappedValue: coordinator)
    }
    
    // MARK: - Body
    public var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appCoordinator)
                .onAppear {
                    appCoordinator.start()
                }
        }
    }
}

// MARK: - App Coordinator
/// Coordinates application-level operations and state
@MainActor
public final class AppCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var appState: AppState = .initializing
    @Published public private(set) var currentUser: User?
    @Published public private(set) var isFirstLaunch: Bool = true
    
    // MARK: - Dependencies
    private let userService: UserServiceProtocol
    private let onboardingService: OnboardingServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init() {
        // Resolve dependencies from container
        self.userService = DependencyContainer.shared.resolve(UserServiceProtocol.self)
        self.onboardingService = DependencyContainer.shared.resolve(OnboardingServiceProtocol.self)
        self.analyticsService = DependencyContainer.shared.resolve(AnalyticsServiceProtocol.self)
    }
    
    // MARK: - Public Interface
    /// Starts the application
    public func start() {
        appState = .starting
        
        // Check if this is the first launch
        checkFirstLaunch()
        
        // Initialize user session
        initializeUserSession()
        
        // Track app launch
        analyticsService.logEvent("app_launched", properties: [
            "is_first_launch": isFirstLaunch
        ])
    }
    
    /// Signs out the current user
    public func signOut() {
        appState = .signingOut
        
        userService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.handleSignOut()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Completes onboarding
    public func completeOnboarding() {
        isFirstLaunch = false
        
        onboardingService.markOnboardingComplete()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.appState = .ready
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    private func checkFirstLaunch() {
        isFirstLaunch = onboardingService.isOnboardingComplete() == false
    }
    
    private func initializeUserSession() {
        userService.getCurrentUser()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                        self?.appState = .ready // Continue without user
                    }
                },
                receiveValue: { [weak self] user in
                    self?.handleUserSessionInitialized(user)
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleUserSessionInitialized(_ user: User?) {
        currentUser = user
        
        if isFirstLaunch {
            appState = .onboarding
        } else {
            appState = .ready
        }
        
        // Track user session
        if let user = user {
            analyticsService.logEvent("user_session_initialized", properties: [
                "user_id": user.id.uuidString
            ])
        }
    }
    
    private func handleSignOut() {
        currentUser = nil
        appState = .ready
        
        analyticsService.logEvent("user_signed_out", properties: [:])
    }
    
    private func handleError(_ error: Error) {
        // Log error
        analyticsService.logError(error, context: "app_coordinator")
        
        // In a real app, you might show an error alert or handle it differently
        print("App Coordinator Error: \(error.localizedDescription)")
    }
}

// MARK: - App State
public enum AppState: Equatable {
    case initializing
    case starting
    case onboarding
    case ready
    case signingOut
}

// MARK: - Supporting Protocols
public protocol UserServiceProtocol {
    func getCurrentUser() -> AnyPublisher<User?, Error>
    func signOut() -> AnyPublisher<Void, Error>
}

public protocol OnboardingServiceProtocol {
    func isOnboardingComplete() -> Bool
    func markOnboardingComplete() -> AnyPublisher<Void, Error>
}

// MARK: - Supporting Types
public struct User: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let email: String
    public let preferences: UserPreferences
    
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.preferences = preferences
    }
}

public struct UserPreferences: Equatable {
    public let meditationPreferences: MeditationUserPreferences
    public let notificationPreferences: NotificationPreferences
    public let accessibilityPreferences: AccessibilityPreferences
    
    public init(
        meditationPreferences: MeditationUserPreferences = MeditationUserPreferences(),
        notificationPreferences: NotificationPreferences = NotificationPreferences(),
        accessibilityPreferences: AccessibilityPreferences = AccessibilityPreferences()
    ) {
        self.meditationPreferences = meditationPreferences
        self.notificationPreferences = notificationPreferences
        self.accessibilityPreferences = accessibilityPreferences
    }
}

public struct NotificationPreferences: Equatable {
    public let enabled: Bool
    public let reminderTime: Date
    public let soundEnabled: Bool
    public let vibrationEnabled: Bool
    
    public init(
        enabled: Bool = true,
        reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        soundEnabled: Bool = true,
        vibrationEnabled: Bool = true
    ) {
        self.enabled = enabled
        self.reminderTime = reminderTime
        self.soundEnabled = soundEnabled
        self.vibrationEnabled = vibrationEnabled
    }
}

public struct AccessibilityPreferences: Equatable {
    public let reduceMotion: Bool
    public let reduceTransparency: Bool
    public let increaseContrast: Bool
    public let voiceOverEnabled: Bool
    
    public init(
        reduceMotion: Bool = false,
        reduceTransparency: Bool = false,
        increaseContrast: Bool = false,
        voiceOverEnabled: Bool = false
    ) {
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
        self.increaseContrast = increaseContrast
        self.voiceOverEnabled = voiceOverEnabled
    }
}

// MARK: - Dependency Container Extension
// Note: Mock services are now registered in DependencyContainer.registerDefaultServices()
