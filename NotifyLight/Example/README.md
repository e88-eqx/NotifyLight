# NotifyLight iOS SDK Example

This example demonstrates how to integrate the NotifyLight iOS SDK into your iOS app.

## Setup

### 1. Configure Your App

Update `AppDelegate.swift` with your NotifyLight server details:

```swift
let configuration = NotifyLight.Configuration(
    apiUrl: URL(string: "https://your-notifylight-server.com")!,
    apiKey: "your-api-key-here",
    userId: "demo-user-123", // Replace with actual user ID
    autoRegisterForNotifications: true,
    enableDebugLogging: true
)
```

### 2. Enable Push Notifications

In your Xcode project:

1. Go to **Project Settings** → **Signing & Capabilities**
2. Add **Push Notifications** capability
3. Add **Background Modes** capability and enable:
   - Remote notifications
   - Background app refresh

### 3. APNs Certificate

Make sure your NotifyLight server is configured with your APNs certificate or key.

## Features Demonstrated

- **Push Notification Setup**: Request permissions and handle tokens
- **Event Handling**: Listen for notification events and in-app messages
- **Manual Operations**: Fetch messages, test notifications, health checks
- **Auto Message Checking**: Automatic polling for new in-app messages
- **UI Integration**: SwiftUI interface showing notifications and messages

## Usage

1. Launch the app
2. Tap "Request Permissions" to enable notifications
3. Use "Test Notification" to verify local notifications work
4. Use "Fetch Messages" to check for server-side in-app messages
5. Send push notifications from your NotifyLight server

## Testing

### Send Test Push Notification

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Test Push",
    "message": "Hello from NotifyLight!",
    "users": ["demo-user-123"],
    "data": {
      "screen": "home"
    }
  }'
```

### Send Test In-App Message

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Welcome!",
    "message": "Welcome to NotifyLight iOS SDK",
    "users": ["demo-user-123"],
    "actions": [
      {
        "id": "ok",
        "title": "Got it!",
        "style": "primary"
      }
    ]
  }'
```

## Key Files

- **AppDelegate.swift**: Main configuration and delegate methods
- **ContentView.swift**: SwiftUI interface with SDK integration examples
- **Info.plist**: Required permissions and capabilities

## Privacy

The SDK includes a privacy manifest (`PrivacyInfo.xcprivacy`) that declares:
- Device ID collection for app functionality
- User ID collection for app functionality  
- No tracking or advertising usage
- No third-party data sharing

This ensures compliance with App Store privacy requirements.