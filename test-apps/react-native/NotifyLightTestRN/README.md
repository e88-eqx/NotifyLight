# NotifyLight React Native Test App

A comprehensive test application for the NotifyLight React Native SDK, designed to verify the "2-hour implementation" promise and test all SDK features.

## Features

- ✅ **Complete SDK Integration Testing**
- ✅ **Real-time Status Monitoring** (SDK, Network, Token)
- ✅ **Push Notification Testing** (iOS APNs & Android FCM)
- ✅ **In-App Message Testing** with native UI
- ✅ **Debug Logging** with exportable logs
- ✅ **Network Connectivity Testing**
- ✅ **Error Scenario Testing**
- ✅ **Settings Management** with persistence
- ✅ **Device Information Display**

## Prerequisites

### Development Environment

- [Node.js](https://nodejs.org/) >= 16
- [React Native CLI](https://reactnative.dev/docs/environment-setup)
- [Xcode](https://developer.apple.com/xcode/) 14+ (for iOS)
- [Android Studio](https://developer.android.com/studio) (for Android)
- [CocoaPods](https://cocoapods.org/) (for iOS dependencies)

### NotifyLight Server

- Running NotifyLight server instance
- Valid API key for your server
- Server accessible from your test devices

## Quick Start

### 1. Install Dependencies

```bash
cd test-apps/react-native/NotifyLightTestRN
npm install
```

### 2. iOS Setup

```bash
# Install iOS dependencies
cd ios
pod install
cd ..

# Run on iOS simulator
npm run ios

# Or run on specific device
npx react-native run-ios --device "Your Device Name"
```

### 3. Android Setup

```bash
# Clean and prepare Android
npm run setup-android

# Run on Android emulator/device
npm run android
```

### 4. Configure Test App

1. Open the app
2. Tap **Settings** in the top-right
3. Configure:
   - **API URL**: Your NotifyLight server URL (e.g., `https://your-server.com`)
   - **API Key**: Your server API key
   - **User ID**: Test user identifier
4. Tap **Done**

### 5. Run Tests

1. Tap **🧪 Run All Tests** to execute comprehensive test suite
2. Monitor results in real-time
3. Check **Logs** for detailed debugging information

## Detailed Setup Instructions

### iOS Configuration

#### 1. Xcode Project Setup

1. Open `ios/NotifyLightTestRN.xcworkspace` in Xcode
2. Select your development team in **Signing & Capabilities**
3. Add **Push Notifications** capability
4. Add **Background Modes** capability and enable:
   - Remote notifications
   - Background app refresh

#### 2. APNs Certificate Setup

1. Create App ID in [Apple Developer Portal](https://developer.apple.com/)
2. Enable Push Notifications service
3. Generate APNs certificate or key
4. Configure your NotifyLight server with APNs credentials

#### 3. Physical Device Testing

- Push notifications **DO NOT work** in iOS Simulator
- Use a physical device for complete testing
- Ensure device is registered for development

### Android Configuration

#### 1. Firebase Setup

1. Create project in [Firebase Console](https://console.firebase.google.com/)
2. Add Android app with package name: `com.notifylighttest`
3. Download `google-services.json`
4. Place in `android/app/` directory

#### 2. FCM Integration

1. Configure your NotifyLight server with Firebase Server Key
2. Enable FCM API in Google Cloud Console
3. Configure notification channels (handled automatically)

#### 3. Emulator Setup

```bash
# Create AVD with Google Play Services
# Recommended: Pixel 5 API 30+ with Play Store
# Enable: Hardware keyboard, Hardware GPU acceleration
```

### Network Configuration

#### localhost Access from Physical Devices

**iOS (Physical Device):**
```bash
# Find your Mac's IP address
ifconfig | grep "inet " | grep -v 127.0.0.1

# Use IP address instead of localhost
# Example: http://192.168.1.100:3000
```

**Android (Physical Device):**
```bash
# Use adb port forwarding
adb reverse tcp:3000 tcp:3000

# Or use your computer's IP address
# Example: http://192.168.1.100:3000
```

## Test Features

### Automated Test Suite

The app includes a comprehensive test suite that verifies:

1. **SDK Initialization** - Confirms proper setup and configuration
2. **Push Permissions** - Tests notification permission requests
3. **Token Registration** - Verifies device token retrieval and server registration
4. **Network Connectivity** - Tests server communication
5. **In-App Messages** - Fetches and displays server messages
6. **Custom Messages** - Tests local message display

### Manual Testing

#### Push Notifications

Test push notifications using curl:

```bash
# Basic push notification
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Test Notification",
    "message": "Hello from NotifyLight!",
    "users": ["your-test-user-id"]
  }'
```

#### In-App Messages

```bash
# In-app message with actions
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "type": "in-app",
    "title": "Welcome Message",
    "message": "Welcome to NotifyLight testing!",
    "users": ["your-test-user-id"],
    "actions": [
      {"id": "ok", "title": "Got it!", "style": "primary"},
      {"id": "learn", "title": "Learn More", "style": "secondary"}
    ]
  }'
```

### Test Scenarios

#### App State Testing

Test notifications in different app states:

1. **Foreground** - App active and visible
2. **Background** - App in background (home button pressed)
3. **Killed** - App terminated by user

#### Network Testing

1. **Connected** - Normal network connectivity
2. **Offline** - No network connection
3. **Poor Connection** - Slow/unstable network
4. **Server Unreachable** - Invalid server URL

#### Error Scenarios

1. **Invalid API Key** - Wrong or missing API key
2. **Invalid User ID** - Non-existent user
3. **Permission Denied** - User denies notification permissions
4. **Token Refresh** - Force token regeneration

## Debugging

### Debug Logs

The app provides comprehensive logging:

- **Info** - General information and successful operations
- **Success** - Successful SDK operations (green)
- **Warning** - Non-critical issues (yellow)
- **Error** - Critical failures (red)

### Common Issues

#### iOS Issues

**Problem: "No token received"**
```
Solution: 
1. Check APNs certificate configuration
2. Ensure push notifications capability is enabled
3. Test on physical device only
4. Check developer portal app ID configuration
```

**Problem: "Permission denied"**
```
Solution:
1. Delete and reinstall app
2. Check iOS Settings > Notifications > App
3. Call requestPermissions() explicitly
```

#### Android Issues

**Problem: "FCM token not received"**
```
Solution:
1. Verify google-services.json is correct
2. Check Firebase project configuration
3. Ensure Google Play Services are available
4. Check network connectivity
```

**Problem: "Build failed"**
```
Solution:
1. Clean project: npm run clean
2. Check Android SDK/NDK versions
3. Verify gradle dependencies
4. Check Firebase console configuration
```

### Performance Benchmarks

Expected performance metrics:

- **SDK Initialization**: < 500ms
- **Token Registration**: < 2 seconds
- **Message Display**: < 100ms
- **Server Response**: < 1 second (local network)

## Test Data Management

### Settings Persistence

App settings are stored in AsyncStorage:
- API URL
- API Key
- User ID
- Auto-register preference

### Data Reset

Use **Reset App** button to:
- Clear all stored settings
- Reset to default configuration
- Clear logs and test results
- Force SDK re-initialization

### Export Logs

Logs can be exported for debugging:
1. Tap **Logs** in header
2. Copy relevant log entries
3. Share with development team

## Success Criteria

The test app validates the "2-hour implementation" promise:

✅ **Setup Time**: Complete setup in < 30 minutes  
✅ **Integration**: SDK integration in < 15 minutes  
✅ **First Notification**: Receive first push in < 5 minutes  
✅ **Full Features**: All features working in < 2 hours  

### Validation Checklist

- [ ] App builds and runs on both platforms
- [ ] SDK initializes successfully
- [ ] Device token is retrieved and registered
- [ ] Push notifications are received in all app states
- [ ] In-app messages display correctly
- [ ] All test scenarios pass
- [ ] No critical errors in logs
- [ ] Performance meets benchmarks

## Troubleshooting

### Build Issues

```bash
# Clean everything
npm run clean
cd ios && xcodebuild clean && cd ..
cd android && ./gradlew clean && cd ..

# Reset React Native cache
npm run reset

# Reinstall dependencies
rm -rf node_modules
npm install
cd ios && pod install && cd ..
```

### SDK Issues

```bash
# Check NotifyLight SDK linking
npx react-native config
npx react-native doctor

# Verify native module integration
# iOS: Check Podfile.lock for notifylight-react-native
# Android: Check settings.gradle includes the module
```

## Support

For issues with the test app:

1. Check this README and troubleshooting section
2. Review debug logs in the app
3. Test with minimal configuration first
4. Verify server connectivity separately
5. Open GitHub issue with logs and device info

## License

MIT License - This test app is provided for SDK verification and development purposes.