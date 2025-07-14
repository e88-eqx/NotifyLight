import UIKit
import NotifyLight
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure NotifyLight
        Task {
            await configureNotifyLight()
        }
        
        return true
    }
    
    // MARK: - NotifyLight Configuration
    
    private func configureNotifyLight() async {
        do {
            // Load configuration from UserDefaults or use defaults
            let userDefaults = UserDefaults.standard
            let apiUrl = userDefaults.string(forKey: "NotifyLight.apiUrl") ?? "http://localhost:3000"
            let apiKey = userDefaults.string(forKey: "NotifyLight.apiKey") ?? "test-api-key-123"
            let userId = userDefaults.string(forKey: "NotifyLight.userId") ?? "test-user-ios-\(UUID().uuidString.prefix(8))"
            
            // Save userId if it was generated
            if userDefaults.string(forKey: "NotifyLight.userId") == nil {
                userDefaults.set(userId, forKey: "NotifyLight.userId")
            }
            
            let configuration = NotifyLight.Configuration(
                apiUrl: URL(string: apiUrl)!,
                apiKey: apiKey,
                userId: userId,
                autoRegisterForNotifications: true,
                enableDebugLogging: true
            )
            
            try await NotifyLight.shared.configure(with: configuration)
            
            // Set up event handlers
            setupNotificationHandlers()
            
            print("✅ NotifyLight configured successfully")
            
        } catch {
            print("❌ Failed to configure NotifyLight: \(error)")
        }
    }
    
    private func setupNotificationHandlers() {
        // Handle notification events
        NotifyLight.shared.onNotification { event in
            DispatchQueue.main.async {
                self.handleNotificationEvent(event)
            }
        }
        
        // Handle in-app messages
        NotifyLight.shared.onMessage { message in
            DispatchQueue.main.async {
                self.handleInAppMessage(message)
            }
        }
    }
    
    private func handleNotificationEvent(_ event: NotificationEvent) {
        switch event {
        case .received(let notification):
            print("📱 Notification received: \(notification.title)")
            
            // Post notification for UI updates
            NotificationCenter.default.post(
                name: NSNotification.Name("NotifyLightNotificationReceived"),
                object: notification
            )
            
        case .opened(let notification):
            print("👆 Notification opened: \(notification.title)")
            
            // Handle notification tap - navigate to relevant screen if needed
            if let data = notification.data,
               let screen = data["screen"] as? String {
                print("Navigate to: \(screen)")
                // Implement navigation logic here
            }
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NotifyLightNotificationOpened"),
                object: notification
            )
            
        case .tokenReceived(let token):
            print("🔑 Device token received: \(token.prefix(20))...")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NotifyLightTokenReceived"),
                object: token
            )
            
        case .tokenRefresh(let token):
            print("🔄 Device token refreshed: \(token.prefix(20))...")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NotifyLightTokenRefreshed"),
                object: token
            )
            
        case .registrationError(let error):
            print("❌ Registration error: \(error.localizedDescription)")
            
            NotificationCenter.default.post(
                name: NSNotification.Name("NotifyLightRegistrationError"),
                object: error
            )
        }
    }
    
    private func handleInAppMessage(_ message: InAppMessage) {
        print("💬 In-app message: \(message.title)")
        
        // Post notification for UI to handle message display
        NotificationCenter.default.post(
            name: NSNotification.Name("NotifyLightInAppMessage"),
            object: message
        )
    }

    // MARK: - Push Notification Delegate Methods
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        print("📱 Device registered for remote notifications")
        NotifyLight.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        NotifyLight.shared.didFailToRegisterForRemoteNotifications(with: error)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📨 Remote notification received: \(userInfo)")
        NotifyLight.shared.didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}