import Foundation
import UserNotifications
import SwiftUI
import UIKit

// MARK: - NotifyLight SDK Configuration

public struct NotifyLightConfiguration {
    let apiUrl: URL
    let apiKey: String
    let userId: String
    
    public init(apiUrl: URL, apiKey: String, userId: String) {
        self.apiUrl = apiUrl
        self.apiKey = apiKey
        self.userId = userId
    }
}

// MARK: - NotifyLight SDK Main Class

public class NotifyLight: ObservableObject {
    
    // Singleton instance
    public static let shared = NotifyLight()
    
    // Configuration
    private var configuration: NotifyLightConfiguration?
    
    // In-app message handlers
    private var inAppMessageHandlers: [(String, String) -> Void] = []
    
    // Published properties for SwiftUI integration
    @Published public var isConfigured = false
    @Published public var currentInAppMessage: InAppMessage?
    
    private init() {}
    
    // MARK: - Configuration
    
    public func configure(with config: NotifyLightConfiguration) async throws {
        print("NotifyLight: Configuring SDK with URL: \(config.apiUrl)")
        print("NotifyLight: User ID: \(config.userId)")
        
        self.configuration = config
        
        // Simulate configuration delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            self.isConfigured = true
        }
        
        print("NotifyLight: SDK configured successfully")
    }
    
    // MARK: - Push Notification Authorization
    
    public func requestPushAuthorization() async throws -> UNAuthorizationStatus {
        print("NotifyLight: Requesting push notification authorization...")
        
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            let settings = await center.notificationSettings()
            
            print("NotifyLight: Push authorization granted: \(granted)")
            print("NotifyLight: Authorization status: \(settings.authorizationStatus.rawValue)")
            
            if granted {
                // Register for remote notifications on main thread
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return settings.authorizationStatus
        } catch {
            print("NotifyLight: Failed to request push authorization: \(error)")
            throw error
        }
    }
    
    // MARK: - In-App Messages
    
    public func checkForInAppMessages() async {
        print("NotifyLight: Checking for in-app messages...")
        
        guard let config = configuration else {
            print("NotifyLight: SDK not configured, skipping message check")
            return
        }
        
        // Simulate API call to check for messages
        do {
            let url = config.apiUrl.appendingPathComponent("messages/\(config.userId)")
            var request = URLRequest(url: url)
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
            
            print("NotifyLight: Checking messages at: \(url)")
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // For demo purposes, we'll simulate finding messages
            print("NotifyLight: Found pending in-app messages")
            
        } catch {
            print("NotifyLight: Error checking for messages: \(error)")
        }
    }
    
    @MainActor
    public func showInAppMessage(title: String, message: String) {
        print("NotifyLight: Showing in-app message - Title: '\(title)', Message: '\(message)'")
        
        let inAppMessage = InAppMessage(
            id: UUID().uuidString,
            title: title,
            message: message,
            timestamp: Date()
        )
        
        // Set the current message (triggers UI update)
        self.currentInAppMessage = inAppMessage
        
        // Notify registered handlers
        inAppMessageHandlers.forEach { handler in
            handler(title, message)
        }
        
        // Auto-dismiss after 5 seconds
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            self.currentInAppMessage = nil
        }
    }
    
    public func registerInAppMessageHandler(_ handler: @escaping (String, String) -> Void) {
        inAppMessageHandlers.append(handler)
    }
    
    // MARK: - Event Tracking
    
    public func trackScreenView(screen: String) {
        print("NotifyLight: Tracking screen view: \(screen)")
        
        // Simulate analytics event
        let event = [
            "event": "screen_view",
            "screen": screen,
            "timestamp": Date().timeIntervalSince1970,
            "user_id": configuration?.userId ?? "unknown"
        ] as [String : Any]
        
        print("NotifyLight: Event tracked: \(event)")
    }
    
    public func trackAssetInteraction(symbol: String) {
        print("NotifyLight: Tracking asset interaction: \(symbol)")
        
        let event = [
            "event": "asset_interaction",
            "symbol": symbol,
            "timestamp": Date().timeIntervalSince1970,
            "user_id": configuration?.userId ?? "unknown"
        ] as [String : Any]
        
        print("NotifyLight: Asset interaction tracked: \(event)")
    }
    
    @MainActor public func triggerContextualMessage(context: String, asset: String) {
        print("NotifyLight: Triggering contextual message for context: \(context), asset: \(asset)")
        
        // For demo purposes, show a contextual message
        let contextualTitle = "Asset Information"
        let contextualMessage = "You selected \(asset). Here's some relevant information!"
        
        showInAppMessage(title: contextualTitle, message: contextualMessage)
    }
    
    // MARK: - Device Registration
    
    public func registerDevice(token: String? = nil) async throws -> String {
        print("NotifyLight: Registering device...")
        
        guard let config = configuration else {
            throw NotifyLightError.notConfigured
        }
        
        let deviceToken = token ?? "mock-device-token-\(UUID().uuidString)"
        
        // Simulate device registration API call
        let url = config.apiUrl.appendingPathComponent("register-device")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let requestBody = [
            "token": deviceToken,
            "platform": "ios",
            "userId": config.userId
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("NotifyLight: Device registration request prepared")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        print("NotifyLight: Device registered successfully with token: \(deviceToken)")
        
        return deviceToken
    }
}

// MARK: - In-App Message Model

public struct InAppMessage: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let message: String
    public let timestamp: Date
    
    public static func == (lhs: InAppMessage, rhs: InAppMessage) -> Bool {
        return lhs.id == rhs.id && lhs.title == rhs.title && lhs.message == rhs.message
    }
}

// MARK: - NotifyLight Errors

public enum NotifyLightError: Error, LocalizedError {
    case notConfigured
    case networkError(String)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "NotifyLight SDK is not configured. Call configure(with:) first."
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}

// MARK: - SwiftUI Integration

public struct InAppMessageView: View {
    let message: InAppMessage
    let onDismiss: () -> Void
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(message.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Text(message.message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Spacer()
                
                Button("Dismiss") {
                    onDismiss()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}
