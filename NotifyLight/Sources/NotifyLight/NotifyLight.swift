import Foundation
import UserNotifications
import UIKit
import SwiftUI

/// Main NotifyLight SDK class for iOS
@MainActor
public final class NotifyLight: ObservableObject {
    
    // MARK: - Singleton
    
    public static let shared = NotifyLight()
    
    // MARK: - Properties
    
    private var apiClient: APIClient?
    private var apnsService: APNSService
    private var configuration: Configuration?
    private var isConfigured = false
    
    @Published public private(set) var isInitialized = false
    @Published public private(set) var currentToken: String?
    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // Event handlers
    private var notificationHandlers: [(NotificationEvent) -> Void] = []
    private var messageHandlers: [(InAppMessage) -> Void] = []
    
    // In-app message management
    private var messageQueue: [InAppMessage] = []
    private var isShowingMessage = false
    private var autoCheckTimer: Timer?
    
    private init() {
        self.apnsService = APNSService.shared
        setupAPNSEventHandling()
    }
    
    // MARK: - Configuration
    
    /// Configuration for NotifyLight SDK
    public struct Configuration {
        public let apiUrl: URL
        public let apiKey: String
        public let userId: String?
        public let autoRegisterForNotifications: Bool
        public let timeoutInterval: TimeInterval
        public let enableDebugLogging: Bool
        
        public init(
            apiUrl: URL,
            apiKey: String,
            userId: String? = nil,
            autoRegisterForNotifications: Bool = true,
            timeoutInterval: TimeInterval = 30,
            enableDebugLogging: Bool = false
        ) {
            self.apiUrl = apiUrl
            self.apiKey = apiKey
            self.userId = userId
            self.autoRegisterForNotifications = autoRegisterForNotifications
            self.timeoutInterval = timeoutInterval
            self.enableDebugLogging = enableDebugLogging
        }
    }
    
    /// Configure NotifyLight SDK
    public func configure(with configuration: Configuration) async throws {
        self.configuration = configuration
        
        // Initialize API client
        self.apiClient = APIClient(
            baseURL: configuration.apiUrl,
            apiKey: configuration.apiKey,
            timeoutInterval: configuration.timeoutInterval
        )
        
        // Initialize APNs service
        try await apnsService.initialize()
        
        // Check current authorization status
        let settings = await apnsService.getNotificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        
        // Auto-register if configured and authorized
        if configuration.autoRegisterForNotifications {
            try await requestPushAuthorization()
        }
        
        self.isConfigured = true
        self.isInitialized = true
        
        logDebug("NotifyLight configured successfully")
    }
    
    // MARK: - Push Notifications
    
    /// Request push notification authorization
    public func requestPushAuthorization() async throws -> UNAuthorizationStatus {
        guard isConfigured else {
            throw NotifyLightError.notConfigured
        }
        
        logDebug("Requesting push notification authorization...")
        
        let status = try await apnsService.requestAuthorization()
        self.authorizationStatus = status
        
        logDebug("Authorization status: \(status)")
        
        if status == .authorized {
            await apnsService.registerForRemoteNotifications()
        }
        
        return status
    }
    
    /// Get current device token
    public func getDeviceToken() -> String? {
        return currentToken
    }
    
    /// Get current authorization status
    public func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await apnsService.getNotificationSettings()
        self.authorizationStatus = settings.authorizationStatus
        return settings.authorizationStatus
    }
    
    // MARK: - Event Handling
    
    /// Add notification event handler
    public func onNotification(_ handler: @escaping (NotificationEvent) -> Void) {
        notificationHandlers.append(handler)
    }
    
    /// Add in-app message handler
    public func onMessage(_ handler: @escaping (InAppMessage) -> Void) {
        messageHandlers.append(handler)
    }
    
    /// Remove all event handlers
    public func removeAllHandlers() {
        notificationHandlers.removeAll()
        messageHandlers.removeAll()
    }
    
    // MARK: - In-App Messages
    
    /// Fetch in-app messages for current user
    public func fetchMessages() async throws -> [InAppMessage] {
        guard let apiClient = apiClient,
              let userId = configuration?.userId else {
            throw NotifyLightError.notConfigured
        }
        
        logDebug("Fetching in-app messages for user: \(userId)")
        
        let response = try await apiClient.fetchMessages(userId: userId)
        let messages = response.messages.filter { !$0.isRead }
        
        logDebug("Fetched \(messages.count) unread messages")
        
        // Add to message queue
        for message in messages {
            if !messageQueue.contains(where: { $0.id == message.id }) {
                messageQueue.append(message)
            }
        }
        
        // Show next message if not currently showing one
        if !isShowingMessage {
            await showNextMessage()
        }
        
        return messages
    }
    
    /// Mark message as read
    public func markMessageAsRead(_ messageId: String) async throws {
        guard let apiClient = apiClient else {
            throw NotifyLightError.notConfigured
        }
        
        logDebug("Marking message as read: \(messageId)")
        
        _ = try await apiClient.markMessageAsRead(messageId: messageId)
        
        // Remove from queue
        messageQueue.removeAll { $0.id == messageId }
    }
    
    /// Enable automatic message checking
    public func enableAutoMessageCheck(interval: TimeInterval = 30) {
        disableAutoMessageCheck() // Clear existing timer
        
        logDebug("Enabling auto message check with interval: \(interval)s")
        
        autoCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try? await self?.fetchMessages()
            }
        }
        
        // Fetch immediately
        Task {
            try? await fetchMessages()
        }
    }
    
    /// Disable automatic message checking
    public func disableAutoMessageCheck() {
        autoCheckTimer?.invalidate()
        autoCheckTimer = nil
        logDebug("Auto message check disabled")
    }
    
    // MARK: - In-App Message Presentation
    
    /// Present an in-app message with native UIKit design
    public func presentMessage(
        _ message: InAppMessage,
        customization: InAppMessageCustomization = .default,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            logDebug("No window available for presenting message")
            return
        }
        
        let messageVC = InAppMessageViewController(
            message: message,
            customization: customization,
            onAction: { [weak self] action in
                self?.handleMessageAction(action, message: message)
            },
            onDismiss: { [weak self] in
                self?.handleMessageDismiss(message)
                completion?()
            }
        )
        
        if let presentedVC = window.rootViewController?.presentedViewController {
            presentedVC.present(messageVC, animated: animated, completion: nil)
        } else {
            window.rootViewController?.present(messageVC, animated: animated, completion: nil)
        }
        
        logDebug("Presenting message: \(message.title)")
    }
    
    /// Present an in-app message with SwiftUI design
    public func presentMessage(
        _ message: InAppMessage,
        swiftUICustomization: InAppMessageSwiftUICustomization,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        // For SwiftUI, we'll use a UIHostingController to present the SwiftUI view
        let messageView = InAppMessageView(
            message: message,
            customization: swiftUICustomization,
            onAction: { [weak self] action in
                self?.handleMessageAction(action, message: message)
            },
            onDismiss: { [weak self] in
                self?.handleMessageDismiss(message)
                completion?()
            }
        )
        
        let hostingController = UIHostingController(rootView: messageView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            logDebug("No window available for presenting SwiftUI message")
            return
        }
        
        if let presentedVC = window.rootViewController?.presentedViewController {
            presentedVC.present(hostingController, animated: animated, completion: nil)
        } else {
            window.rootViewController?.present(hostingController, animated: animated, completion: nil)
        }
        
        logDebug("Presenting SwiftUI message: \(message.title)")
    }
    
    /// Show a simple alert-style message
    public func showAlert(
        title: String,
        message: String,
        actions: [MessageAction] = [],
        completion: (() -> Void)? = nil
    ) {
        let inAppMessage = InAppMessage(
            id: UUID().uuidString,
            title: title,
            message: message,
            actions: actions.isEmpty ? [MessageAction(id: "ok", title: "OK", style: .primary)] : actions
        )
        
        presentMessage(inAppMessage, customization: .alert, completion: completion)
    }
    
    /// Show a card-style message
    public func showCard(
        title: String,
        message: String,
        actions: [MessageAction] = [],
        completion: (() -> Void)? = nil
    ) {
        let inAppMessage = InAppMessage(
            id: UUID().uuidString,
            title: title,
            message: message,
            actions: actions
        )
        
        presentMessage(inAppMessage, customization: .card, completion: completion)
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    public func updateBadgeCount(_ count: Int) async {
        await apnsService.updateBadgeCount(count)
    }
    
    /// Clear app badge
    public func clearBadge() async {
        await apnsService.clearBadge()
    }
    
    // MARK: - Testing
    
    /// Schedule a local notification for testing
    public func scheduleTestNotification(
        title: String = "Test Notification",
        body: String = "This is a test notification from NotifyLight",
        delay: TimeInterval = 5
    ) async throws {
        try await apnsService.scheduleLocalNotification(
            title: title,
            body: body,
            delay: delay
        )
    }
    
    /// Check server health
    public func checkServerHealth() async throws -> Bool {
        guard let apiClient = apiClient else {
            throw NotifyLightError.notConfigured
        }
        
        let response = try await apiClient.healthCheck()
        return response.status == "ok"
    }
    
    // MARK: - AppDelegate Integration
    
    /// Call this from AppDelegate's didRegisterForRemoteNotificationsWithDeviceToken
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        apnsService.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    /// Call this from AppDelegate's didFailToRegisterForRemoteNotificationsWithError
    public func didFailToRegisterForRemoteNotifications(with error: Error) {
        apnsService.didFailToRegisterForRemoteNotifications(with: error)
    }
    
    /// Call this from AppDelegate's didReceiveRemoteNotification
    public func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        apnsService.didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
    }
    
    // MARK: - Private Methods
    
    private func setupAPNSEventHandling() {
        apnsService.addEventHandler { [weak self] event in
            Task { @MainActor in
                await self?.handleNotificationEvent(event)
            }
        }
    }
    
    private func handleNotificationEvent(_ event: NotificationEvent) async {
        switch event {
        case .tokenReceived(let token):
            self.currentToken = token
            await registerDeviceWithServer(token: token)
            
        case .tokenRefresh(let token):
            self.currentToken = token
            await registerDeviceWithServer(token: token)
            
        case .received(let notification), .opened(let notification):
            logDebug("Notification \(event): \(notification.title)")
            
        case .registrationError(let error):
            logDebug("Registration error: \(error.localizedDescription)")
        }
        
        // Notify handlers
        for handler in notificationHandlers {
            handler(event)
        }
    }
    
    private func registerDeviceWithServer(token: String) async {
        guard let apiClient = apiClient,
              let configuration = configuration else {
            return
        }
        
        do {
            let request = DeviceRegistrationRequest(
                token: token,
                platform: "ios",
                userId: configuration.userId
            )
            
            logDebug("Registering device with server...")
            let response = try await apiClient.registerDevice(request)
            
            if response.success {
                logDebug("Device registered successfully: \(response.deviceId ?? "unknown")")
            } else {
                logDebug("Device registration failed: \(response.message ?? "unknown error")")
            }
        } catch {
            logDebug("Failed to register device: \(error.localizedDescription)")
        }
    }
    
    private func showNextMessage() async {
        guard !isShowingMessage, !messageQueue.isEmpty else {
            return
        }
        
        let message = messageQueue.removeFirst()
        isShowingMessage = true
        
        logDebug("Showing message: \(message.title)")
        
        // Notify handlers
        for handler in messageHandlers {
            handler(message)
        }
        
        // Mark as read
        try? await markMessageAsRead(message.id)
        
        // Reset showing state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isShowingMessage = false
            
            // Show next message if available
            Task { @MainActor in
                await self?.showNextMessage()
            }
        }
    }
    
    private func logDebug(_ message: String) {
        if configuration?.enableDebugLogging == true {
            print("[NotifyLight] \(message)")
        }
    }
    
    // MARK: - Message Action Handling
    
    private func handleMessageAction(_ action: MessageAction, message: InAppMessage) {
        logDebug("Message action: \(action.title) for message: \(message.title)")
        
        // Mark message as read when action is taken
        Task {
            try? await markMessageAsRead(message.id)
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Notify handlers about the action
        for handler in messageHandlers {
            handler(message)
        }
    }
    
    private func handleMessageDismiss(_ message: InAppMessage) {
        logDebug("Message dismissed: \(message.title)")
        
        // Mark message as read when dismissed
        Task {
            try? await markMessageAsRead(message.id)
        }
        
        // Remove from queue if it exists
        messageQueue.removeAll { $0.id == message.id }
        
        // Show next message if available
        if !messageQueue.isEmpty {
            Task {
                await showNextMessage()
            }
        }
    }
}

// MARK: - Error Types

public enum NotifyLightError: LocalizedError {
    case notConfigured
    case invalidConfiguration
    case authorizationDenied
    case registrationFailed(Error)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "NotifyLight is not configured. Call configure(with:) first."
        case .invalidConfiguration:
            return "Invalid configuration provided."
        case .authorizationDenied:
            return "Push notification authorization denied by user."
        case .registrationFailed(let error):
            return "Device registration failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}