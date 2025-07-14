# NotifyLight React Native SDK

Lightweight React Native SDK for NotifyLight self-hosted notifications. Zero-config push notifications with direct native integration.

## Features

- 🚀 **Zero Configuration** - Initialize with just 2 lines of code
- 📱 **Native Integration** - Direct APNs/FCM without Firebase dependencies  
- 🔄 **Auto Token Management** - Automatic registration and refresh handling
- 🎯 **Unified API** - Same interface for iOS and Android
- 📦 **Minimal Bundle** - Plain JavaScript, no TypeScript overhead
- 🔧 **All App States** - Handles foreground, background, and quit states

## Installation

```bash
npm install notifylight-react-native
```

### iOS Setup

1. **Link the native module** (React Native 0.60+ autolinking):
   ```bash
   cd ios && pod install
   ```

2. **Add to AppDelegate.m**:
   ```objc
   #import "NotifyLight.h"
   
   - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
     [[NotifyLight sharedInstance] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
   }
   
   - (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
     [[NotifyLight sharedInstance] didFailToRegisterForRemoteNotificationsWithError:error];
   }
   
   - (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
     [[NotifyLight sharedInstance] didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
   }
   ```

3. **Add Push Notifications capability** in Xcode project settings.

4. **Add your APNs certificate/key** to your NotifyLight server configuration.

### Android Setup

1. **Add to MainApplication.java**:
   ```java
   import com.notifylight.NotifyLightPackage;
   
   @Override
   protected List<ReactPackage> getPackages() {
     return Arrays.<ReactPackage>asList(
       new MainReactPackage(),
       new NotifyLightPackage() // Add this line
     );
   }
   ```

2. **Create Firebase Messaging Service** (create `MyFirebaseMessagingService.java`):
   ```java
   package com.yourapp;
   
   import com.google.firebase.messaging.FirebaseMessagingService;
   import com.google.firebase.messaging.RemoteMessage;
   import com.notifylight.NotifyLightModule;
   import android.os.Bundle;
   
   public class MyFirebaseMessagingService extends FirebaseMessagingService {
   
     @Override
     public void onNewToken(String token) {
       super.onNewToken(token);
       NotifyLightModule.handleTokenRefresh(this, token);
     }
   
     @Override
     public void onMessageReceived(RemoteMessage remoteMessage) {
       super.onMessageReceived(remoteMessage);
       
       String title = "";
       String body = "";
       Bundle data = new Bundle();
       
       if (remoteMessage.getNotification() != null) {
         title = remoteMessage.getNotification().getTitle();
         body = remoteMessage.getNotification().getBody();
       }
       
       for (String key : remoteMessage.getData().keySet()) {
         data.putString(key, remoteMessage.getData().get(key));
       }
       
       NotifyLightModule.handleNotificationReceived(this, title, body, data);
     }
   }
   ```

3. **Add to AndroidManifest.xml**:
   ```xml
   <service
     android:name=".MyFirebaseMessagingService"
     android:exported="false">
     <intent-filter>
       <action android:name="com.google.firebase.MESSAGING_EVENT" />
     </intent-filter>
   </service>
   ```

4. **Add google-services.json** to your `android/app/` directory.

## Usage

### Basic Setup

```javascript
import NotifyLight, { NOTIFICATION_TYPES } from 'notifylight-react-native';

// Initialize with your NotifyLight server
await NotifyLight.initialize({
  apiUrl: 'https://your-notifylight-server.com',
  apiKey: 'your-api-key',
  userId: 'user123', // Optional: identify the user
  autoRegister: true, // Automatically register device (default: true)
  requestPermissions: true, // Request permissions on iOS (default: true)
});

// Listen for all notification events
const unsubscribe = NotifyLight.onNotification((type, data) => {
  switch (type) {
    case NOTIFICATION_TYPES.RECEIVED:
      console.log('Notification received:', data);
      break;
    case NOTIFICATION_TYPES.OPENED:
      console.log('Notification opened:', data);
      break;
    case NOTIFICATION_TYPES.TOKEN_RECEIVED:
      console.log('Token received:', data.token);
      break;
    default:
      console.log('Notification event:', type, data);
  }
});

// Clean up listener when component unmounts
// unsubscribe();
```

### Advanced Usage

```javascript
import NotifyLight, { 
  NOTIFICATION_TYPES, 
  APP_STATES, 
  ERROR_CODES 
} from 'notifylight-react-native';

// Initialize with custom options
await NotifyLight.initialize({
  apiUrl: 'https://your-notifylight-server.com',
  apiKey: 'your-api-key',
  userId: 'user123',
  autoRegister: false, // Manual registration
  showNotificationsWhenInForeground: true, // Show alerts in foreground
  enableLogs: true // Enable debug logging
});

// Manual device registration
try {
  await NotifyLight.register();
  console.log('Device registered successfully');
} catch (error) {
  console.error('Registration failed:', error);
}

// Get current device token
try {
  const token = await NotifyLight.getToken();
  console.log('Device token:', token);
} catch (error) {
  console.error('No token available:', error);
}

// Request permissions manually (iOS only)
try {
  const permissions = await NotifyLight.requestPermissions();
  console.log('Permissions:', permissions);
} catch (error) {
  console.error('Permission denied:', error);
}

// Handle different notification types
NotifyLight.onNotification((type, data) => {
  switch (type) {
    case NOTIFICATION_TYPES.RECEIVED:
      // Notification received while app is in foreground
      if (data.appState === APP_STATES.FOREGROUND) {
        showInAppNotification(data.title, data.message);
      }
      break;
      
    case NOTIFICATION_TYPES.OPENED:
      // User tapped on notification
      if (data.data.screen) {
        navigateToScreen(data.data.screen);
      }
      break;
      
    case NOTIFICATION_TYPES.TOKEN_RECEIVED:
    case NOTIFICATION_TYPES.TOKEN_REFRESH:
      // Token received or refreshed - SDK handles registration automatically
      console.log('Token updated:', data.token);
      break;
      
    case NOTIFICATION_TYPES.REGISTRATION_ERROR:
      // Handle registration errors
      if (data.code === ERROR_CODES.PERMISSIONS_DENIED) {
        showPermissionDialog();
      }
      break;
  }
});

// Cleanup when done
NotifyLight.cleanup();
```

### In-App Messages

The SDK provides native-feeling in-app modals for server-sent messages:

```javascript
import NotifyLight, { MESSAGE_TYPES, InAppModal } from 'notifylight-react-native';

// Check for messages manually
const result = await NotifyLight.checkForMessages();
console.log(`Found ${result.messages.length} messages`);

// Enable automatic checking (every 30 seconds)
NotifyLight.enableAutoCheck(30000);

// Listen for message events
NotifyLight.onMessageDisplayed((type, data) => {
  switch (type) {
    case MESSAGE_TYPES.DISPLAYED:
      console.log('Message shown:', data.message.title);
      break;
    case MESSAGE_TYPES.ACTION_PRESSED:
      console.log('Action pressed:', data.action.title);
      break;
    case MESSAGE_TYPES.DISMISSED:
      console.log('Message dismissed');
      break;
  }
});

// Show a custom message
NotifyLight.showMessage({
  id: 'welcome-message',
  title: 'Welcome!',
  message: 'Thanks for using NotifyLight',
  actions: [
    {
      id: 'learn-more',
      title: 'Learn More',
      style: 'primary'
    },
    {
      id: 'dismiss',
      title: 'Dismiss',
      style: 'secondary'
    }
  ]
});

// Custom modal component (optional - for manual control)
function MyComponent() {
  const [showModal, setShowModal] = useState(false);
  const [currentMessage, setCurrentMessage] = useState(null);

  return (
    <InAppModal
      visible={showModal}
      message={currentMessage}
      onClose={() => setShowModal(false)}
      onActionPress={(action, message) => {
        console.log('Action:', action.title);
        // Handle action
      }}
      style={customStyles}
      enableSwipeToDismiss={true}
      animationType="slide"
    />
  );
}
```

### Custom Styling

Customize the appearance of in-app messages:

```javascript
const customStyle = {
  modal: {
    backgroundColor: '#F8F9FA',
    borderRadius: 20,
    marginHorizontal: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '700',
    color: '#1A202C',
  },
  message: {
    fontSize: 16,
    color: '#4A5568',
  },
  primaryButton: {
    backgroundColor: '#4299E1',
    borderRadius: 12,
  },
  secondaryButton: {
    backgroundColor: '#EDF2F7',
    borderRadius: 12,
  },
};

// Apply custom styling
<InAppModal style={customStyle} /* other props */ />
```

### Creating Server-Side Messages

Create in-app messages from your NotifyLight server:

```bash
# Basic in-app message
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Welcome Message",
    "message": "Welcome to our app!",
    "users": ["user123"]
  }'

# Message with actions
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Update Available",
    "message": "A new version is available. Update now?",
    "users": ["user123"],
    "actions": [
      {"id": "update", "title": "Update Now", "style": "primary"},
      {"id": "later", "title": "Later", "style": "secondary"}
    ]
  }'
```

## Notification Data Format

The SDK provides a consistent notification format across platforms:

```javascript
{
  id: "unique-notification-id",
  title: "Notification Title",
  message: "Notification message body", 
  data: {
    // Custom data from your server
    screen: "ProfileScreen",
    userId: "123"
  },
  appState: "foreground" | "background" | "quit",
  receivedAt: 1640995200000, // Timestamp
  platform: "ios" | "android",
  raw: { /* Original platform-specific data */ }
}
```

## Error Handling

```javascript
import { ERROR_CODES } from 'notifylight-react-native';

try {
  await NotifyLight.initialize(config);
} catch (error) {
  switch (error.code) {
    case ERROR_CODES.INVALID_CONFIG:
      console.error('Configuration error:', error.message);
      break;
    case ERROR_CODES.PERMISSIONS_DENIED:
      console.error('Permissions denied');
      break;
    case ERROR_CODES.NETWORK_ERROR:
      console.error('Network error:', error.message);
      break;
    default:
      console.error('Unknown error:', error);
  }
}
```

## Testing

To test notifications during development:

1. **Use your NotifyLight server** to send test notifications
2. **Test on physical devices** - Push notifications don't work in simulators
3. **Test all app states** - Foreground, background, and quit
4. **Verify token registration** - Check your server logs

```bash
# Send test notification using curl
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Test Notification",
    "message": "Hello from NotifyLight!",
    "users": ["user123"]
  }'
```

## Requirements

- React Native >= 0.70.0
- iOS >= 10.0
- Android API Level >= 21
- For iOS: Valid APNs certificate/key
- For Android: Firebase project with FCM enabled

## Troubleshooting

### iOS Issues

- **No token received**: Check APNs certificate/key configuration
- **Permissions denied**: Call `requestPermissions()` explicitly
- **Background notifications not working**: Verify Background App Refresh is enabled

### Android Issues

- **No token received**: Check `google-services.json` configuration
- **Service not found**: Verify `FirebaseMessagingService` is correctly configured
- **Notifications not showing**: Check notification channel configuration

### Common Issues

- **Network errors**: Verify your NotifyLight server URL and API key
- **Module not found**: Ensure proper linking and rebuild your app
- **Token not registering**: Check server logs for registration errors

## Support

- [GitHub Issues](https://github.com/notifylight/notifylight/issues)
- [Documentation](https://docs.notifylight.com)
- [Discord Community](https://discord.gg/notifylight)

## License

MIT License - see LICENSE file for details.