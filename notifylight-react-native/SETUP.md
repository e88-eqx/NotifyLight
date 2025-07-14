# NotifyLight React Native SDK Setup Guide

This guide walks you through setting up the NotifyLight React Native SDK for both iOS and Android platforms.

## Prerequisites

- React Native development environment set up
- Physical devices for testing (push notifications don't work in simulators)
- NotifyLight server running and accessible
- Valid APNs certificates (iOS) and FCM configuration (Android)

## Quick Start

### 1. Install the Package

```bash
npm install notifylight-react-native
```

### 2. Platform-Specific Setup

Choose your platform and follow the detailed instructions below:

- [iOS Setup](#ios-setup)
- [Android Setup](#android-setup)

### 3. Initialize in Your App

```javascript
import NotifyLight from 'notifylight-react-native';

await NotifyLight.initialize({
  apiUrl: 'https://your-notifylight-server.com',
  apiKey: 'your-api-key',
  userId: 'user123'
});
```

---

## iOS Setup

### Step 1: Install iOS Dependencies

```bash
cd ios && pod install
```

### Step 2: Enable Push Notifications

1. Open your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" and add "Push Notifications"
5. Add "Background Modes" capability and enable "Remote notifications"

### Step 3: Update AppDelegate.m

Add the following imports at the top of `AppDelegate.m`:

```objc
#import "NotifyLight.h"
```

Add these methods to your `AppDelegate.m`:

```objc
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

### Step 4: Configure APNs

1. **Generate APNs Key** (recommended) or Certificate in Apple Developer Console
2. **Configure your NotifyLight server** with the APNs credentials:
   ```bash
   APNS_KEY_ID=your-key-id
   APNS_TEAM_ID=your-team-id
   APNS_KEY_PATH=/path/to/AuthKey_KEYID.p8
   APNS_PRODUCTION=false  # Set to true for production
   ```

### Step 5: Test iOS Implementation

1. Build and run on a physical iOS device
2. Grant notification permissions when prompted
3. Check logs for "Token received" message
4. Send a test notification from your server

---

## Android Setup

### Step 1: Add Firebase Configuration

1. **Create a Firebase project** at https://console.firebase.google.com
2. **Add your Android app** to the Firebase project
3. **Download `google-services.json`** and place it in `android/app/`
4. **Add FCM credentials** to your NotifyLight server:
   ```bash
   FCM_PROJECT_ID=your-firebase-project-id
   FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY\n-----END PRIVATE KEY-----\n"
   FCM_CLIENT_EMAIL=firebase-adminsdk-xxxxx@your-project.iam.gserviceaccount.com
   ```

### Step 2: Update Build Configuration

Add to `android/build.gradle` (project level):

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

Add to `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
}
```

### Step 3: Update MainApplication.java

Add the import and package:

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

### Step 4: Create Firebase Messaging Service

Create `android/app/src/main/java/com/yourapp/MyFirebaseMessagingService.java`:

```java
package com.yourapp; // Replace with your package name

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.notifylight.NotifyLightModule;
import android.os.Bundle;
import android.util.Log;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = "MyFCMService";

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "Refreshed token: " + token);
        NotifyLightModule.handleTokenRefresh(this, token);
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        Log.d(TAG, "From: " + remoteMessage.getFrom());

        String title = "";
        String body = "";
        Bundle data = new Bundle();

        // Extract notification data
        if (remoteMessage.getNotification() != null) {
            title = remoteMessage.getNotification().getTitle();
            body = remoteMessage.getNotification().getBody();
            Log.d(TAG, "Message Notification Title: " + title);
            Log.d(TAG, "Message Notification Body: " + body);
        }

        // Extract custom data
        for (String key : remoteMessage.getData().keySet()) {
            String value = remoteMessage.getData().get(key);
            data.putString(key, value);
            Log.d(TAG, "Message data: " + key + " = " + value);
        }

        // Handle the message
        NotifyLightModule.handleNotificationReceived(this, title, body, data);
    }
}
```

### Step 5: Update AndroidManifest.xml

Add the service to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:

```xml
<service
    android:name=".MyFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

### Step 6: Test Android Implementation

1. Build and run on a physical Android device
2. Check logs for "Refreshed token" message
3. Send a test notification from your server

---

## Testing Your Setup

### 1. Verify Token Registration

Check your NotifyLight server logs for device registration:

```bash
# You should see logs like:
# Device registered: ios token for user user123
# Device registered: android token for user user123
```

### 2. Send Test Notification

Use curl or your server's admin interface:

```bash
curl -X POST https://your-notifylight-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Test Notification",
    "message": "Hello from NotifyLight!",
    "users": ["user123"]
  }'
```

### 3. Test Different App States

- **Foreground**: App is open and active
- **Background**: App is minimized but running
- **Quit**: App is completely closed

### 4. Debug Common Issues

**iOS Issues:**
- No token: Check APNs configuration and certificates
- Permissions denied: Call `requestPermissions()` explicitly
- Background notifications not working: Enable Background App Refresh

**Android Issues:**
- No token: Verify `google-services.json` and Firebase configuration
- Service not found: Check `MyFirebaseMessagingService` setup
- Notifications not showing: Verify notification channels (Android 8+)

**Common Issues:**
- Network errors: Check server URL and API key
- Module not found: Rebuild app after installation
- Token not registering: Check server logs for errors

## Integration Checklist

### iOS
- [ ] Pod install completed
- [ ] Push Notifications capability added
- [ ] Background Modes capability added
- [ ] AppDelegate methods implemented
- [ ] APNs credentials configured on server
- [ ] Tested on physical device

### Android
- [ ] Firebase project created
- [ ] google-services.json added
- [ ] Build configuration updated
- [ ] NotifyLightPackage added to MainApplication
- [ ] MyFirebaseMessagingService created
- [ ] Service added to AndroidManifest.xml
- [ ] FCM credentials configured on server
- [ ] Tested on physical device

### Both Platforms
- [ ] NotifyLight.initialize() called in app
- [ ] Event listener set up with onNotification()
- [ ] Test notifications sent and received
- [ ] All app states tested (foreground/background/quit)
- [ ] Error handling implemented

## Next Steps

Once setup is complete:

1. **Implement your notification UI** - Show in-app alerts, badges, etc.
2. **Handle notification data** - Navigate to specific screens based on notification content
3. **Add user preferences** - Allow users to control notification settings
4. **Monitor and analytics** - Track notification delivery and engagement
5. **Production deployment** - Update to production APNs/FCM credentials

## Support

If you encounter issues:

1. Check the [troubleshooting section](README.md#troubleshooting) in the main README
2. Enable debug logging with `enableLogs: true`
3. Check device and server logs
4. Create an issue on [GitHub](https://github.com/notifylight/notifylight/issues)

## Example Implementation

See the complete example app in the `example/` directory for a working implementation with all features demonstrated.