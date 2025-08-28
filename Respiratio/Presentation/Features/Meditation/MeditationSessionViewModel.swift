import Foundation
import Combine
import SwiftUI

// MARK: - Presentation ViewModel
/// ViewModel for meditation session management
/// This belongs to the presentation layer and handles UI state and user interactions
@MainActor
public final class MeditationSessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public private(set) var currentSession: MeditationSession?
    @Published public private(set) var sessionState: SessionState = .idle
    @Published public private(set) var elapsedTime: TimeInterval = 0
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var isLoading = false
    
    // MARK: - Dependencies
    private let applicationService: MeditationApplicationService
    private let audioService: AudioServiceProtocol
    private let hapticService: HapticServiceProtocol
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private nonisolated(unsafe) var timer: Timer?
    private var sessionStartTime: Date?
    
    // MARK: - Initialization
    public init(
        applicationService: MeditationApplicationService,
        audioService: AudioServiceProtocol,
        hapticService: HapticServiceProtocol
    ) {
        self.applicationService = applicationService
        self.audioService = audioService
        self.hapticService = hapticService
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Public Interface
    /// Starts a new meditation session
    /// - Parameters:
    ///   - preset: The meditation preset to use
    ///   - preferences: User preferences for the session
    public func startSession(preset: MeditationPreset, preferences: MeditationUserPreferences) {
        guard sessionState == .idle else {
            errorMessage = "Cannot start session: another session is already active"
            return
        }
        
        isLoading = true
        sessionState = .starting
        
        applicationService.startSession(preset: preset, preferences: preferences)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                        self?.sessionState = .idle
                    }
                },
                receiveValue: { [weak self] session in
                    self?.handleSessionStarted(session)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Pauses the current meditation session
    public func pauseSession() {
        guard let session = currentSession,
              sessionState == .active else {
            errorMessage = "Cannot pause: no active session"
            return
        }
        
        sessionState = .pausing
        
        applicationService.pauseSession(sessionId: session.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] session in
                    self?.handleSessionPaused(session)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Resumes a paused meditation session
    public func resumeSession() {
        guard let session = currentSession,
              sessionState == .paused else {
            errorMessage = "Cannot resume: no paused session"
            return
        }
        
        sessionState = .resuming
        
        applicationService.resumeSession(sessionId: session.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] session in
                    self?.handleSessionResumed(session)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Completes the current meditation session
    public func completeSession() {
        guard let session = currentSession,
              sessionState == .active else {
            errorMessage = "Cannot complete: no active session"
            return
        }
        
        sessionState = .completing
        
        applicationService.completeSession(sessionId: session.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error)
                    }
                },
                receiveValue: { [weak self] session in
                    self?.handleSessionCompleted(session)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Cancels the current meditation session
    public func cancelSession() {
        guard let session = currentSession else {
            errorMessage = "Cannot cancel: no active session"
            return
        }
        
        sessionState = .cancelling
        
        // Stop audio and timer
        stopAudio()
        stopTimer()
        
        // Reset state
        currentSession = nil
        sessionState = .idle
        elapsedTime = 0
        progress = 0.0
        sessionStartTime = nil
        
        hapticService.trigger(.cancellation)
    }
    
    /// Dismisses any error messages
    public func dismissError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func handleSessionStarted(_ session: MeditationSession) {
        currentSession = session
        sessionState = .active
        sessionStartTime = Date()
        
        startTimer()
        startAudio()
        hapticService.trigger(.start)
        
        // Log session start
        logSessionEvent("session_started", session: session)
    }
    
    private func handleSessionPaused(_ session: MeditationSession) {
        currentSession = session
        sessionState = .paused
        
        stopTimer()
        pauseAudio()
        hapticService.trigger(.pause)
        
        logSessionEvent("session_paused", session: session)
    }
    
    private func handleSessionResumed(_ session: MeditationSession) {
        currentSession = session
        sessionState = .active
        
        startTimer()
        resumeAudio()
        hapticService.trigger(.resume)
        
        logSessionEvent("session_resumed", session: session)
    }
    
    private func handleSessionCompleted(_ session: MeditationSession) {
        currentSession = session
        sessionState = .completed
        
        stopTimer()
        stopAudio()
        hapticService.trigger(.success)
        
        // Calculate final statistics
        elapsedTime = session.sessionDuration
        progress = 1.0
        
        logSessionEvent("session_completed", session: session)
        
        // Auto-reset after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.resetToIdle()
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        hapticService.trigger(.error)
        
        // Log error
        logError(error, context: "meditation_session")
    }
    
    private func resetToIdle() {
        currentSession = nil
        sessionState = .idle
        elapsedTime = 0
        progress = 0.0
        sessionStartTime = nil
    }
    
    // MARK: - Timer Management
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private nonisolated func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard let startTime = sessionStartTime else { return }
        
        elapsedTime = Date().timeIntervalSince(startTime)
        
        if let session = currentSession {
            progress = min(elapsedTime / session.preset.duration, 1.0)
            
            // Check if session should auto-complete
            if progress >= 1.0 && sessionState == .active {
                completeSession()
            }
        }
    }
    
    // MARK: - Audio Management
    private func startAudio() {
        // Audio service would be started by the use case
        // This is just for UI state management
    }
    
    private func pauseAudio() {
        // Audio service would be paused by the use case
        // This is just for UI state management
    }
    
    private func resumeAudio() {
        // Audio service would be resumed by the use case
        // This is just for UI state management
    }
    
    private func stopAudio() {
        // Audio service would be stopped by the use case
        // This is just for UI state management
    }
    
    // MARK: - Logging
    private func logSessionEvent(_ event: String, session: MeditationSession) {
        // In a real app, this would use a logging service
        print("Meditation Session Event: \(event) - Session ID: \(session.id)")
    }
    
    private func logError(_ error: Error, context: String) {
        // In a real app, this would use a logging service
        print("Error in \(context): \(error.localizedDescription)")
    }
}

// MARK: - Supporting Types
public enum SessionState: Equatable {
    case idle
    case starting
    case active
    case pausing
    case paused
    case resuming
    case completing
    case completed
    case cancelling
}

public protocol HapticServiceProtocol {
    func trigger(_ feedback: HapticFeedback)
}

public enum HapticFeedback {
    case start
    case pause
    case resume
    case complete
    case success
    case error
    case cancellation
}
