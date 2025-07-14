# In-App Messages Usage Guide

This guide demonstrates how to use the NotifyLight iOS SDK's in-app message functionality in both UIKit and SwiftUI applications.

## Overview

The NotifyLight iOS SDK provides native in-app message UI components that follow iOS design guidelines and support both UIKit and SwiftUI integration patterns.

## Key Features

- **Native iOS Design**: Follows iOS design language with proper blur effects and animations
- **UIKit & SwiftUI Support**: Complete integration for both UI frameworks
- **Haptic Feedback**: Provides tactile feedback for user interactions
- **Dynamic Type**: Supports iOS accessibility features
- **Customizable**: Extensive customization options for styling and behavior
- **Gesture Support**: Swipe-to-dismiss and tap-to-dismiss gestures
- **Action Handling**: Support for multiple action buttons with different styles

## Basic Usage

### UIKit Integration

```swift
import NotifyLight

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup message handling
        NotifyLight.shared.onMessage { message in
            print("Message received: \(message.title)")
        }
        
        // Show a simple alert
        NotifyLight.shared.showAlert(
            title: "Welcome!",
            message: "Welcome to our app!",
            completion: {
                print("Alert dismissed")
            }
        )
    }
}
```

### SwiftUI Integration

```swift
import SwiftUI
import NotifyLight

struct ContentView: View {
    @State private var showingMessage = false
    @State private var message = InAppMessage(
        id: "welcome",
        title: "Welcome!",
        message: "Welcome to our app!",
        actions: [
            MessageAction(id: "ok", title: "OK", style: .primary)
        ]
    )
    
    var body: some View {
        VStack {
            Button("Show Message") {
                showingMessage = true
            }
        }
        .inAppMessage(
            isPresented: $showingMessage,
            message: message,
            onAction: { action in
                print("Action: \(action.title)")
            }
        )
    }
}
```

## Advanced Usage Examples

### Custom Styling (UIKit)

```swift
// Create custom message
let message = InAppMessage(
    id: "custom",
    title: "Custom Message",
    message: "This message has custom styling",
    actions: [
        MessageAction(id: "primary", title: "Primary", style: .primary),
        MessageAction(id: "secondary", title: "Secondary", style: .secondary)
    ]
)

// Custom styling
var customization = InAppMessageCustomization.default
customization.backgroundColor = .systemPurple.withAlphaComponent(0.1)
customization.titleColor = .systemPurple
customization.primaryActionColor = .systemPurple
customization.cornerRadius = 24
customization.enableHapticFeedback = true
customization.animationDuration = 0.6

// Present with custom styling
NotifyLight.shared.presentMessage(
    message,
    customization: customization,
    completion: {
        print("Custom message dismissed")
    }
)
```

### Custom Styling (SwiftUI)

```swift
struct CustomMessageView: View {
    @State private var showingMessage = false
    
    var body: some View {
        Button("Show Custom Message") {
            showingMessage = true
        }
        .inAppMessage(
            isPresented: $showingMessage,
            message: customMessage,
            customization: customSwiftUIStyle,
            onAction: handleAction
        )
    }
    
    private var customMessage: InAppMessage {
        InAppMessage(
            id: "custom-swiftui",
            title: "SwiftUI Custom",
            message: "This message uses SwiftUI styling",
            actions: [
                MessageAction(id: "awesome", title: "Awesome!", style: .primary),
                MessageAction(id: "customize", title: "Customize", style: .secondary)
            ]
        )
    }
    
    private var customSwiftUIStyle: InAppMessageSwiftUICustomization {
        var style = InAppMessageSwiftUICustomization.default
        style.backgroundColor = Color.purple.opacity(0.1)
        style.titleColor = .purple
        style.primaryActionBackgroundColor = .purple
        style.cornerRadius = 24
        style.enableHapticFeedback = true
        return style
    }
    
    private func handleAction(_ action: MessageAction) {
        print("Action: \(action.title)")
    }
}
```

### Survey Message Example

```swift
// Create survey message
let surveyMessage = InAppMessage(
    id: "survey",
    title: "Quick Survey",
    message: "How would you rate your experience?",
    actions: [
        MessageAction(id: "excellent", title: "Excellent", style: .primary),
        MessageAction(id: "good", title: "Good", style: .secondary),
        MessageAction(id: "average", title: "Average", style: .secondary),
        MessageAction(id: "poor", title: "Poor", style: .destructive)
    ]
)

// UIKit presentation
NotifyLight.shared.presentMessage(surveyMessage) {
    print("Survey completed")
}

// SwiftUI presentation
struct SurveyView: View {
    @State private var showingSurvey = false
    
    var body: some View {
        Button("Show Survey") {
            showingSurvey = true
        }
        .inAppMessage(
            isPresented: $showingSurvey,
            message: surveyMessage,
            onAction: handleSurveyAction
        )
    }
    
    private func handleSurveyAction(_ action: MessageAction) {
        switch action.id {
        case "excellent", "good", "average", "poor":
            submitRating(action.id)
        default:
            break
        }
    }
    
    private func submitRating(_ rating: String) {
        print("Rating submitted: \(rating)")
        // Submit to analytics or server
    }
}
```

### Server Message Integration

```swift
// Fetch messages from server
func fetchAndShowMessages() {
    Task {
        do {
            let messages = try await NotifyLight.shared.fetchMessages()
            
            for message in messages {
                // UIKit
                NotifyLight.shared.presentMessage(message)
                
                // SwiftUI - use state management
                DispatchQueue.main.async {
                    self.currentMessage = message
                    self.showingMessage = true
                }
            }
        } catch {
            print("Error fetching messages: \(error)")
        }
    }
}

// Enable automatic message checking
NotifyLight.shared.enableAutoMessageCheck(interval: 30) // Check every 30 seconds
```

## Customization Options

### UIKit Customization

```swift
var customization = InAppMessageCustomization()

// Colors
customization.backgroundColor = .systemBackground
customization.titleColor = .label
customization.messageColor = .secondaryLabel
customization.primaryActionColor = .systemBlue
customization.secondaryActionColor = .systemGray6

// Typography
customization.titleFont = .preferredFont(forTextStyle: .headline)
customization.messageFont = .preferredFont(forTextStyle: .body)
customization.actionButtonFont = .preferredFont(forTextStyle: .callout)

// Layout
customization.cornerRadius = 16
customization.horizontalPadding = 20
customization.contentPadding = 24
customization.actionSpacing = 12

// Behavior
customization.allowBackgroundDismiss = true
customization.allowSwipeToDismiss = true
customization.enableHapticFeedback = true
customization.showDismissButton = true

// Animation
customization.animationDuration = 0.4
customization.animationSpringDamping = 0.8
```

### SwiftUI Customization

```swift
var customization = InAppMessageSwiftUICustomization()

// Colors
customization.backgroundColor = Color(.systemBackground)
customization.backgroundMaterial = .ultraThinMaterial
customization.titleColor = .primary
customization.messageColor = .secondary

// Typography
customization.titleFont = .headline
customization.messageFont = .body
customization.actionButtonFont = .callout.weight(.medium)
customization.maxDynamicTypeSize = .accessibility1

// Layout
customization.cornerRadius = 16
customization.horizontalMargin = 20
customization.contentPadding = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
customization.actionsLayout = .horizontal

// Behavior
customization.allowBackgroundDismiss = true
customization.allowSwipeToDismiss = true
customization.enableHapticFeedback = true

// Animation
customization.presentationAnimation = .spring(response: 0.4, dampingFraction: 0.8)
customization.dismissAnimation = .easeInOut(duration: 0.3)
```

## Preset Styles

The SDK includes several preset styles:

### UIKit Presets

```swift
// Default style
NotifyLight.shared.presentMessage(message, customization: .default)

// Minimal style
NotifyLight.shared.presentMessage(message, customization: .minimal)

// Card style
NotifyLight.shared.presentMessage(message, customization: .card)

// Alert style
NotifyLight.shared.presentMessage(message, customization: .alert)
```

### SwiftUI Presets

```swift
// Default style
.inAppMessage(isPresented: $showing, message: message, customization: .default)

// Minimal style
.inAppMessage(isPresented: $showing, message: message, customization: .minimal)

// Card style
.inAppMessage(isPresented: $showing, message: message, customization: .card)

// Compact style
.inAppMessage(isPresented: $showing, message: message, customization: .compact)
```

## Best Practices

### 1. Message Timing

- Don't show messages immediately on app launch
- Wait for user to complete onboarding
- Respect user's current context

```swift
// Good: Wait for appropriate moment
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    NotifyLight.shared.showAlert(title: "Welcome!", message: "...")
}

// Bad: Show immediately
NotifyLight.shared.showAlert(title: "Welcome!", message: "...")
```

### 2. Action Handling

- Always handle all possible actions
- Provide meaningful action titles
- Use appropriate action styles

```swift
private func handleAction(_ action: MessageAction) {
    switch action.id {
    case "primary":
        performPrimaryAction()
    case "secondary":
        performSecondaryAction()
    case "destructive":
        performDestructiveAction()
    default:
        // Always handle unknown actions
        print("Unknown action: \(action.id)")
    }
}
```

### 3. Accessibility

- Use proper action titles for screen readers
- Support Dynamic Type
- Provide alternative text for images

```swift
// Enable Dynamic Type support
var customization = InAppMessageCustomization.default
customization.titleFont = .preferredFont(forTextStyle: .headline)
customization.messageFont = .preferredFont(forTextStyle: .body)
```

### 4. Performance

- Limit number of queued messages
- Use appropriate animation durations
- Avoid heavy processing in action handlers

```swift
// Limit message queue
if messageQueue.count > 3 {
    messageQueue.removeFirst()
}
```

## Testing

### Local Testing

```swift
// Test with various message types
func testMessages() {
    // Simple alert
    NotifyLight.shared.showAlert(title: "Test", message: "Simple alert")
    
    // Multi-action message
    let message = InAppMessage(
        id: "test",
        title: "Test Message",
        message: "This is a test message",
        actions: [
            MessageAction(id: "test1", title: "Test 1", style: .primary),
            MessageAction(id: "test2", title: "Test 2", style: .secondary)
        ]
    )
    NotifyLight.shared.presentMessage(message)
}
```

### Server Testing

```bash
# Send test message via server
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Test Message",
    "message": "This is a test message from server",
    "users": ["user123"],
    "actions": [
      {
        "id": "ok",
        "title": "OK",
        "style": "primary"
      }
    ]
  }'
```

## Migration from React Native SDK

If you're migrating from the React Native SDK, here are the key differences:

### React Native
```javascript
NotifyLight.showMessage({
  title: "Title",
  message: "Message",
  actions: [...]
});
```

### iOS Native
```swift
let message = InAppMessage(
    title: "Title",
    message: "Message",
    actions: [...]
)
NotifyLight.shared.presentMessage(message)
```

The native iOS SDK provides more granular control over styling and behavior while maintaining the same core functionality as the React Native SDK.