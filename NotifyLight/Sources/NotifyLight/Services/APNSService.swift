import Foundation
import UserNotifications
import UIKit

/// Service for handling Apple Push Notification Service (APNs) integration
@MainActor
public final class APNSService: NSObject, ObservableObject {
    public static let shared = APNSService()
    
    private var notificationCenter: UNUserNotificationCenter
    private var eventHandlers: [(NotificationEvent) -> Void] = []
    private var isInitialized = false
    
    private override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        setupNotificationCenter()
    }
    
    // MARK: - Configuration
    
    /// Initialize APNs service
    public func initialize() async throws {
        guard !isInitialized else { return }
        
        // Set delegate
        notificationCenter.delegate = self
        
        // Configure notification categories if needed
        await configureNotificationCategories()
        
        isInitialized = true
    }
    
    /// Request notification permissions
    public func requestAuthorization() async throws -> UNAuthorizationStatus {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        let granted = try await notificationCenter.requestAuthorization(options: options)
        let settings = await notificationCenter.notificationSettings()
        
        if granted && settings.authorizationStatus == .authorized {
            await registerForRemoteNotifications()
        }
        
        return settings.authorizationStatus
    }
    
    /// Register for remote notifications
    public func registerForRemoteNotifications() async {
        guard await UIApplication.shared.isRegisteredForRemoteNotifications == false else {
            return
        }
        
        await UIApplication.shared.registerForRemoteNotifications()
    }
    
    /// Get current notification settings
    public func getNotificationSettings() async -> UNNotificationSettings {
        return await notificationCenter.notificationSettings()
    }
    
    // MARK: - Event Handling
    
    /// Add event handler for notification events
    public func addEventHandler(_ handler: @escaping (NotificationEvent) -> Void) {
        eventHandlers.append(handler)
    }
    
    /// Remove all event handlers
    public func removeAllEventHandlers() {
        eventHandlers.removeAll()
    }
    
    // MARK: - Token Management
    
    /// Handle device token registration
    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        notifyEventHandlers(.tokenReceived(token))
    }
    
    /// Handle device token registration failure
    public func didFailToRegisterForRemoteNotifications(with error: Error) {
        notifyEventHandlers(.registrationError(error))
    }
    
    // MARK: - Notification Handling
    
    /// Handle remote notification received in foreground
    public func didReceiveRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let notification = createNotificationFromUserInfo(userInfo)
        notifyEventHandlers(.received(notification))
        
        // Always call completion handler
        completionHandler(.newData)
    }
    
    /// Create local notification for testing
    public func scheduleLocalNotification(
        title: String,
        body: String,
        data: [String: Any]? = nil,
        delay: TimeInterval = 0
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let data = data {
            content.userInfo = data
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await notificationCenter.add(request)
    }
    
    // MARK: - Badge Management
    
    /// Update app badge count
    public func updateBadgeCount(_ count: Int) async {
        await UIApplication.shared.setApplicationIconBadgeNumber(count)
    }
    
    /// Clear app badge
    public func clearBadge() async {
        await updateBadgeCount(0)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCenter() {
        notificationCenter.delegate = self
    }
    
    private func configureNotificationCategories() async {
        // Define notification categories for interactive notifications
        let categories: Set<UNNotificationCategory> = []
        await notificationCenter.setNotificationCategories(categories)
    }
    
    private func createNotificationFromUserInfo(_ userInfo: [AnyHashable: Any]) -> NotifyLightNotification {
        let aps = userInfo["aps"] as? [String: Any] ?? [:]
        let alert = aps["alert"] as? [String: Any] ?? [:]
        
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""
        
        // Extract custom data (everything except aps)
        var customData: [String: Any] = [:]
        for (key, value) in userInfo {
            if let stringKey = key as? String, stringKey != "aps" {
                customData[stringKey] = value
            }
        }
        
        return NotifyLightNotification(
            id: customData["id"] as? String,
            title: title,
            message: body,
            data: customData.isEmpty ? nil : customData,
            type: .push
        )
    }
    
    private func notifyEventHandlers(_ event: NotificationEvent) {
        for handler in eventHandlers {
            handler(event)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension APNSService: UNUserNotificationCenterDelegate {
    
    /// Called when a notification is delivered to a foreground app
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let notificationObj = createNotificationFromUserInfo(userInfo)
        notifyEventHandlers(.received(notificationObj))
        
        // Show notification in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    /// Called when user interacts with a notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let notification = createNotificationFromUserInfo(userInfo)
        notifyEventHandlers(.opened(notification))
        
        completionHandler()
    }
}

// MARK: - Background Task Support

extension APNSService {
    
    /// Handle background app refresh for notification processing
    public func handleBackgroundAppRefresh() async -> UIBackgroundFetchResult {
        // Implement background processing logic here
        // For now, just return new data
        return .newData
    }
    
    /// Process silent notification in background
    public func processSilentNotification(_ userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        // Handle silent notifications for background processing
        let notification = createNotificationFromUserInfo(userInfo)
        notifyEventHandlers(.received(notification))
        
        return .newData
    }
}