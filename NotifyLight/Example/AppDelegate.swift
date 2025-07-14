import UIKit
import NotifyLight

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Configure NotifyLight
        Task {
            await configureNotifyLight()
        }
        
        return true
    }
    
    // MARK: - NotifyLight Configuration
    
    private func configureNotifyLight() async {
        do {
            // Configure with your NotifyLight server details
            let configuration = NotifyLight.Configuration(
                apiUrl: URL(string: "https://your-notifylight-server.com")!,
                apiKey: "your-api-key-here",
                userId: "demo-user-123", // Replace with actual user ID
                autoRegisterForNotifications: true,
                enableDebugLogging: true // Enable for development
            )
            
            try await NotifyLight.shared.configure(with: configuration)
            
            // Set up event handlers
            setupNotificationHandlers()
            
            // Enable auto message checking (optional)
            NotifyLight.shared.enableAutoMessageCheck(interval: 30)
            
            print("✅ NotifyLight configured successfully")
            
        } catch {
            print("❌ Failed to configure NotifyLight: \(error)")
        }
    }
    
    private func setupNotificationHandlers() {
        // Handle notification events
        NotifyLight.shared.onNotification { event in
            DispatchQueue.main.async {
                switch event {
                case .received(let notification):
                    print("📱 Notification received: \(notification.title)")
                    // Handle foreground notification
                    
                case .opened(let notification):
                    print("👆 Notification opened: \(notification.title)")
                    // Handle notification tap - navigate to relevant screen
                    if let data = notification.data,
                       let screen = data["screen"] as? String {
                        // Navigate to specific screen
                        print("Navigate to: \(screen)")
                    }
                    
                case .tokenReceived(let token):
                    print("🔑 Device token received: \(token.prefix(20))...")
                    
                case .tokenRefresh(let token):
                    print("🔄 Device token refreshed: \(token.prefix(20))...")
                    
                case .registrationError(let error):
                    print("❌ Registration error: \(error.localizedDescription)")
                }
            }
        }
        
        // Handle in-app messages
        NotifyLight.shared.onMessage { message in
            DispatchQueue.main.async {
                print("💬 In-app message: \(message.title)")
                // Show custom UI for message if needed
                // The SDK handles automatic display by default
            }
        }
    }

    // MARK: - Push Notification Delegate Methods
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotifyLight.shared.didRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotifyLight.shared.didFailToRegisterForRemoteNotifications(with: error)
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        NotifyLight.shared.didReceiveRemoteNotification(userInfo, completionHandler: completionHandler)
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}