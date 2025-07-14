# NotifyLight iOS SDK

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-13.0+-blue.svg)](https://developer.apple.com/ios/)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods](https://img.shields.io/badge/CocoaPods-Compatible-red.svg)](https://cocoapods.org)

Lightweight iOS SDK for NotifyLight self-hosted notifications. Zero-configuration push notifications with direct APNs integration.

## Features

- 🚀 **Zero Configuration** - Initialize with just 2 lines of code
- 📱 **Direct APNs Integration** - No Firebase dependencies required
- 🔄 **Auto Token Management** - Automatic registration and refresh handling
- 💬 **In-App Messages** - Server-sent messages with automatic queueing
- 🎯 **Modern Swift APIs** - Full async/await support with Combine integration
- 🔒 **Privacy-Focused** - Comprehensive privacy manifest included
- 📦 **Minimal Dependencies** - Pure Swift, no external dependencies
- 🧪 **Comprehensive Testing** - Unit tests and integration examples

## Requirements

- iOS 13.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/notifylight/notifylight-ios.git", from: "1.0.0")
]
```

Or add via Xcode: **File** → **Add Package Dependencies** → Enter the repository URL.

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'NotifyLight', '~> 1.0'
```

Then run:
```bash
pod install
```

## Quick Start

### 1. Configure in AppDelegate

```swift
import UIKit
import NotifyLight

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        Task {
            await configureNotifyLight()
        }
        
        return true
    }
    
    private func configureNotifyLight() async {
        do {
            let configuration = NotifyLight.Configuration(
                apiUrl: URL(string: "https://your-notifylight-server.com")!,
                apiKey: "your-api-key",
                userId: "user123"
            )
            
            try await NotifyLight.shared.configure(with: configuration)
            
            // Set up event handlers
            NotifyLight.shared.onNotification { event in
                switch event {
                case .received(let notification):
                    print("📱 Notification: \(notification.title)")
                case .opened(let notification):
                    print("👆 Opened: \(notification.title)")
                case .tokenReceived(let token):
                    print("🔑 Token: \(token)")
                case .tokenRefresh(let token):
                    print("🔄 Token refreshed")
                case .registrationError(let error):
                    print("❌ Error: \(error)")
                }
            }
            
        } catch {
            print("Failed to configure NotifyLight: \(error)")
        }
    }
    
    // MARK: - Push Notification Delegates
    
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
}
```

### 2. Request Permissions

```swift
import NotifyLight

// Request notification permissions
do {
    let status = try await NotifyLight.shared.requestPushAuthorization()
    print("Authorization status: \(status)")
} catch {
    print("Permission request failed: \(error)")
}
```

### 3. Handle In-App Messages

```swift
// Listen for in-app messages
NotifyLight.shared.onMessage { message in
    print("💬 Message: \(message.title)")
    // Display custom UI or let SDK handle automatically
}

// Enable automatic message checking
NotifyLight.shared.enableAutoMessageCheck(interval: 30)

// Or fetch manually
do {
    let messages = try await NotifyLight.shared.fetchMessages()
    print("Fetched \(messages.count) messages")
} catch {
    print("Failed to fetch messages: \(error)")
}
```

## Configuration Options

```swift
let configuration = NotifyLight.Configuration(
    apiUrl: URL(string: "https://your-server.com")!,
    apiKey: "your-api-key",
    userId: "user123",                        // Optional: identify the user
    autoRegisterForNotifications: true,       // Auto-request permissions
    timeoutInterval: 30,                      // Network timeout
    enableDebugLogging: false                 // Debug logging
)
```

## Advanced Usage

### Custom Event Handling

```swift
NotifyLight.shared.onNotification { event in
    switch event {
    case .received(let notification):
        // Handle foreground notification
        if notification.data?["urgent"] as? Bool == true {
            showUrgentAlert(notification)
        }
        
    case .opened(let notification):
        // Handle notification tap
        if let screen = notification.data?["screen"] as? String {
            navigateToScreen(screen)
        }
        
    case .tokenReceived(let token):
        // Token received - SDK automatically registers with server
        analytics.setDeviceToken(token)
        
    case .registrationError(let error):
        // Handle registration errors
        showErrorMessage("Push notifications unavailable")
    }
}
```

### In-App Message Actions

```swift
NotifyLight.shared.onMessage { message in
    // Handle message with custom UI
    if message.actions.isEmpty {
        showSimpleAlert(message)
    } else {
        showActionSheet(message) { actionId in
            // Handle action selection
            switch actionId {
            case "update":
                openAppStore()
            case "settings":
                openSettings()
            default:
                break
            }
        }
    }
}
```

### SwiftUI Integration

```swift
import SwiftUI
import NotifyLight

struct ContentView: View {
    @StateObject private var notifyLight = NotifyLight.shared
    @State private var messages: [InAppMessage] = []
    
    var body: some View {
        VStack {
            Text("Authorization: \(authStatusText)")
                .foregroundColor(notifyLight.authorizationStatus == .authorized ? .green : .red)
            
            if let token = notifyLight.currentToken {
                Text("Token: \(token.prefix(20))...")
                    .font(.caption)
            }
            
            Button("Request Permissions") {
                Task {
                    try? await notifyLight.requestPushAuthorization()
                }
            }
            .disabled(!notifyLight.isInitialized)
            
            List(messages, id: \.id) { message in
                VStack(alignment: .leading) {
                    Text(message.title)
                        .font(.headline)
                    Text(message.message)
                        .font(.body)
                }
            }
        }
        .onAppear {
            setupEventHandlers()
        }
    }
    
    private var authStatusText: String {
        switch notifyLight.authorizationStatus {
        case .authorized: return "Authorized"
        case .denied: return "Denied"
        case .notDetermined: return "Not Determined"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
    
    private func setupEventHandlers() {
        notifyLight.onMessage { message in
            DispatchQueue.main.async {
                messages.append(message)
            }
        }
    }
}
```

## Server Integration

### Send Push Notification

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Hello from Server",
    "message": "This is a push notification",
    "users": ["user123"],
    "data": {
      "screen": "ProfileScreen",
      "urgent": true
    }
  }'
```

### Send In-App Message

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Update Available",
    "message": "A new version is available. Update now?",
    "users": ["user123"],
    "actions": [
      {
        "id": "update",
        "title": "Update Now",
        "style": "primary"
      },
      {
        "id": "later",
        "title": "Later",
        "style": "secondary"
      }
    ]
  }'
```

## Privacy & Security

The SDK includes a comprehensive privacy manifest (`PrivacyInfo.xcprivacy`) that declares:

- **Device ID**: Collected for app functionality (push token registration)
- **User ID**: Collected for app functionality (message targeting)
- **No Tracking**: No data is used for tracking or advertising
- **No Third-Party Sharing**: All data stays within your NotifyLight infrastructure

### Data Usage

- **Device Token**: Securely transmitted to your NotifyLight server for push delivery
- **User ID**: Used to target notifications and messages to specific users  
- **Usage Analytics**: None collected by default
- **Crash Reporting**: None collected by default

## Testing

### Local Testing

```swift
// Schedule test notification
try await NotifyLight.shared.scheduleTestNotification(
    title: "Test Notification",
    body: "This is a test",
    delay: 5
)

// Check server health
let isHealthy = try await NotifyLight.shared.checkServerHealth()
print("Server healthy: \(isHealthy)")
```

### Device Testing

1. **Physical Device Required**: Push notifications don't work in simulator
2. **Valid Certificate**: Ensure your NotifyLight server has valid APNs credentials
3. **Background Testing**: Test with app in background and quit states
4. **Permission States**: Test with different authorization states

## Troubleshooting

### Common Issues

**Token not received:**
- Verify APNs certificate/key in your NotifyLight server
- Check device network connection
- Ensure app has notification permissions

**Notifications not showing:**
- Check notification settings in device Settings app
- Verify payload format matches APNs specification
- Check server logs for delivery errors

**Registration failures:**
- Verify API URL and API key configuration
- Check network connectivity
- Review server logs for registration endpoint errors

### Debug Logging

Enable debug logging during development:

```swift
let configuration = NotifyLight.Configuration(
    // ... other config
    enableDebugLogging: true
)
```

This will print detailed logs about:
- Configuration and initialization
- Token registration and refresh
- Network requests and responses
- Event handling and errors

## Example App

See the [Example](Example/) directory for a complete iOS app demonstrating all SDK features:

- Push notification setup and handling
- In-app message display and actions
- SwiftUI integration patterns
- Event handling examples
- Testing utilities

## API Reference

### NotifyLight

Main SDK class providing all functionality.

#### Configuration

```swift
static func configure(with configuration: Configuration) async throws
```

#### Push Notifications

```swift
func requestPushAuthorization() async throws -> UNAuthorizationStatus
func getDeviceToken() -> String?
func getAuthorizationStatus() async -> UNAuthorizationStatus
```

#### Event Handling

```swift
func onNotification(_ handler: @escaping (NotificationEvent) -> Void)
func onMessage(_ handler: @escaping (InAppMessage) -> Void)
func removeAllHandlers()
```

#### In-App Messages

```swift
func fetchMessages() async throws -> [InAppMessage]
func markMessageAsRead(_ messageId: String) async throws
func enableAutoMessageCheck(interval: TimeInterval = 30)
func disableAutoMessageCheck()
```

#### Utilities

```swift
func updateBadgeCount(_ count: Int) async
func clearBadge() async
func scheduleTestNotification(title: String, body: String, delay: TimeInterval) async throws
func checkServerHealth() async throws -> Bool
```

### Models

#### NotificationEvent

```swift
enum NotificationEvent {
    case received(NotifyLightNotification)
    case opened(NotifyLightNotification)
    case tokenReceived(String)
    case tokenRefresh(String)
    case registrationError(Error)
}
```

#### InAppMessage

```swift
struct InAppMessage {
    let id: String
    let title: String
    let message: String
    let actions: [MessageAction]
    let data: [String: Any]?
    let createdAt: Date
    let expiresAt: Date?
    let isRead: Bool
}
```

#### MessageAction

```swift
struct MessageAction {
    let id: String
    let title: String
    let style: ActionStyle  // .primary, .secondary, .destructive
    let data: [String: Any]?
}
```

## Requirements for App Store

1. **Privacy Manifest**: Included automatically with the SDK
2. **Permissions**: Request notification permissions appropriately
3. **Background Modes**: Add if using background notification processing
4. **APNs Entitlement**: Required for push notifications

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support

- [GitHub Issues](https://github.com/notifylight/notifylight/issues)
- [Documentation](https://docs.notifylight.com)
- [Discord Community](https://discord.gg/notifylight)