# NotifyLight Troubleshooting Guide

Common issues and solutions when testing NotifyLight SDKs and backend components.

## Server Issues

### Test Server Won't Start

#### Problem: Port Already in Use
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution:**
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or use a different port
PORT=3001 node test-server.js
```

#### Problem: Missing Dependencies
```
Error: Cannot find module 'express'
```

**Solution:**
```bash
cd test-apps/utilities
npm install express cors uuid
```

#### Problem: Permission Denied
```
Error: EACCES: permission denied, open 'test-server.js'
```

**Solution:**
```bash
chmod +x test-apps/utilities/test-server.js
# Or run with node directly
node test-apps/utilities/test-server.js
```

### API Connection Issues

#### Problem: Connection Refused
```
curl: (7) Failed to connect to localhost port 3000: Connection refused
```

**Solutions:**
1. Verify server is running: `ps aux | grep test-server`
2. Check firewall settings
3. Use correct IP address:
   - For Android emulator: `http://10.0.2.2:3000`
   - For iOS simulator: `http://localhost:3000`
   - For physical devices: `http://YOUR_LOCAL_IP:3000`

#### Problem: 401 Unauthorized
```json
{"success": false, "message": "API key is required"}
```

**Solution:**
```bash
# Ensure API key header is included
curl -H "X-API-Key: test-api-key-123" http://localhost:3000/validate
```

#### Problem: 429 Rate Limited
```json
{"success": false, "message": "Rate limit exceeded"}
```

**Solution:**
```bash
# Wait for rate limit window to reset (default: 1 minute)
# Or restart the test server to reset counters
```

## React Native Issues

### Installation Problems

#### Problem: npm Install Fails
```
npm ERR! code ERESOLVE
npm ERR! ERESOLVE unable to resolve dependency tree
```

**Solutions:**
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Use legacy peer deps
npm install --legacy-peer-deps
```

#### Problem: iOS Pod Install Fails
```
[!] Unable to find a specification for `NotifyLight`
```

**Solutions:**
```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install

# If still failing, update CocoaPods
sudo gem install cocoapods
pod repo update
```

### Build Issues

#### Problem: Metro Can't Resolve Module
```
error: bundling failed: Error: Unable to resolve module `@notifylight/react-native`
```

**Solutions:**
```bash
# Reset Metro cache
npx react-native start --reset-cache

# Clear watchman
watchman watch-del-all

# Reset React Native cache
npx react-native-clean-project
```

#### Problem: Android Build Fails
```
error: package com.google.firebase.messaging does not exist
```

**Solutions:**
```bash
# Ensure google-services.json is in android/app/
# Clean and rebuild
cd android
./gradlew clean
cd ..
npx react-native run-android
```

#### Problem: iOS Build Fails
```
error: 'NotifyLight/NotifyLight-Swift.h' file not found
```

**Solutions:**
```bash
# Clean iOS build
cd ios
xcodebuild clean
rm -rf build/
cd ..

# Re-run pod install
cd ios && pod install && cd ..
npx react-native run-ios
```

### Runtime Issues

#### Problem: App Crashes on Launch
```
2024-01-01 10:00:00.000 [error] Native module cannot be null
```

**Solutions:**
1. Verify native module linking
2. Check iOS/Android minimum version requirements
3. Ensure proper initialization:
```javascript
import { NotifyLight } from '@notifylight/react-native';

// Initialize before any other calls
NotifyLight.configure({
  apiUrl: 'http://localhost:3000',
  apiKey: 'test-api-key-123'
});
```

#### Problem: Push Notifications Not Received
**Checklist:**
1. ✅ Device registered for push notifications
2. ✅ Valid device token obtained
3. ✅ App in foreground/background as expected
4. ✅ Server sending notifications successfully
5. ✅ Certificate configuration correct (production vs sandbox)

**Debug Steps:**
```javascript
// Enable debug logging
NotifyLight.configure({
  // ... other config
  enableDebugLogging: true
});

// Check device token
const token = await NotifyLight.getDeviceToken();
console.log('Device token:', token);

// Verify server connectivity
const health = await NotifyLight.checkServerHealth();
console.log('Server healthy:', health);
```

### Platform-Specific Issues

#### iOS Simulator
- **Push notifications don't work**: Use physical device for push testing
- **Certificate errors**: Use development certificates for testing
- **App Store Connect issues**: Use sandbox environment

#### Android Emulator
- **Google Play Services missing**: Use emulator with Google APIs
- **Network connectivity**: Use `10.0.2.2` instead of `localhost`
- **FCM registration fails**: Ensure google-services.json is correct

## Native iOS SDK Issues

### Xcode Build Problems

#### Problem: Swift Package Manager Fails
```
error: failed to clone repository https://github.com/notifylight/ios-sdk.git
```

**Solutions:**
```bash
# For local development, use local path
# In Xcode: File > Add Package Dependencies > Add Local...
# Select the NotifyLight directory

# Or build locally
cd NotifyLight
swift build
```

#### Problem: Missing UserNotifications Framework
```
error: No such module 'UserNotifications'
```

**Solution:**
- Ensure deployment target is iOS 10.0+
- Add UserNotifications framework to project if needed

#### Problem: Signing Issues
```
error: Provisioning profile doesn't include the application identifier
```

**Solutions:**
1. Update bundle identifier in project settings
2. Ensure provisioning profile includes push notification entitlement
3. Use automatic signing for development

### Runtime Issues

#### Problem: APNs Token Not Generated
```
NotifyLight: Failed to register for push notifications
```

**Debug Steps:**
```swift
// Check authorization status
let center = UNUserNotificationCenter.current()
center.getNotificationSettings { settings in
    print("Authorization status: \(settings.authorizationStatus)")
}

// Request permissions explicitly
try await notifyLight.requestPushAuthorization()
```

#### Problem: In-App Messages Not Displaying
**Checklist:**
1. ✅ Messages fetched successfully from server
2. ✅ Message data format is correct
3. ✅ View controller hierarchy allows presentation
4. ✅ No modal views blocking presentation

**Debug:**
```swift
// Enable verbose logging
let config = NotifyLight.Configuration(
    // ... other config
    enableDebugLogging: true
)

// Check message retrieval
let messages = try await notifyLight.fetchMessages()
print("Retrieved \(messages.count) messages")

// Test message presentation
let testMessage = InAppMessage(
    id: "test",
    title: "Test",
    message: "Testing",
    actions: []
)
notifyLight.presentMessage(testMessage)
```

## Network and Connectivity Issues

### Local Network Problems

#### Problem: Can't Connect from Device to Local Server
**For iOS Simulator:**
```bash
# Use localhost or 127.0.0.1
export NOTIFYLIGHT_API_URL="http://localhost:3000"
```

**For Android Emulator:**
```bash
# Use special IP for host machine
export NOTIFYLIGHT_API_URL="http://10.0.2.2:3000"
```

**For Physical Devices:**
```bash
# Find your local IP
ipconfig getifaddr en0  # macOS
ip route get 1 | awk '{print $7}'  # Linux

# Use your actual IP
export NOTIFYLIGHT_API_URL="http://192.168.1.100:3000"
```

#### Problem: HTTPS Required
```
error: cleartext HTTP traffic not permitted
```

**Solutions:**
1. **iOS**: Add App Transport Security exception:
```xml
<!-- iOS Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

2. **Android**: Add network security config:
```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">192.168.1.0/24</domain>
    </domain-config>
</network-security-config>
```

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

### Certificate and SSL Issues

#### Problem: Certificate Verification Failed
```
error: SSL certificate problem: self signed certificate
```

**Development Solutions:**
```bash
# For curl testing, ignore certificates
curl -k https://localhost:3000/health

# For production, use proper certificates
```

**App Solutions:**
- Use proper SSL certificates in production
- Implement certificate pinning for security
- Test with both self-signed and valid certificates

## Push Notification Service Issues

### APNs (iOS) Issues

#### Problem: Invalid Certificate
```
error: certificate verify failed: certificate has expired
```

**Solutions:**
1. Renew APNs certificate in Apple Developer Portal
2. Update certificate files on server
3. Verify certificate bundle ID matches app

#### Problem: Wrong Environment
```
error: BadDeviceToken
```

**Solutions:**
- Use sandbox certificates for development
- Use production certificates for App Store builds
- Ensure token is from correct environment

### FCM (Android) Issues

#### Problem: Invalid Server Key
```
error: 401 Unauthorized
```

**Solutions:**
1. Verify server key in Firebase Console
2. Check that project ID matches
3. Use service account key for better security

#### Problem: Registration Token Not Valid
```
error: InvalidRegistration
```

**Solutions:**
1. Refresh the registration token
2. Ensure app package name matches Firebase project
3. Check that google-services.json is correct

## Development Environment Issues

### Node.js and npm Issues

#### Problem: Node Version Mismatch
```
error: The engine "node" is incompatible with this module
```

**Solution:**
```bash
# Check Node version
node --version

# Install correct Node version (use nvm)
nvm install 18
nvm use 18

# Or update package.json engines
```

#### Problem: npm Permission Issues
```
error: EACCES: permission denied, mkdir '/usr/local/lib/node_modules'
```

**Solutions:**
```bash
# Use nvm to avoid permission issues
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Or fix npm permissions
sudo chown -R $(whoami) /usr/local/lib/node_modules
```

### Development Tools

#### Problem: Watchman Issues
```
error: Watchman error: std::__1::system_error: open: /Users/...: Operation not permitted
```

**Solution:**
```bash
# Reset watchman
watchman shutdown-server
watchman watch-del-all

# Grant necessary permissions in System Preferences > Security & Privacy
```

#### Problem: Xcode Command Line Tools Missing
```
error: xcrun: error: invalid active developer path
```

**Solution:**
```bash
# Install Xcode command line tools
xcode-select --install

# Or reset path if Xcode is installed
sudo xcode-select -r
```

## Testing and Debugging

### Debug Logging

#### Enable Comprehensive Logging

**Server:**
```javascript
// In test-server.js, add detailed logging
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  console.log('Headers:', req.headers);
  console.log('Body:', req.body);
  next();
});
```

**React Native:**
```javascript
// Enable detailed logging
NotifyLight.configure({
  // ... other config
  enableDebugLogging: true
});

// Monitor all events
NotifyLight.onTokenReceived((token) => {
  console.log('Token received:', token);
});

NotifyLight.onNotificationReceived((notification) => {
  console.log('Notification received:', notification);
});
```

**iOS:**
```swift
// Enable debug logging
let config = NotifyLight.Configuration(
    // ... other config
    enableDebugLogging: true
)

// Add custom logging
NotificationCenter.default.addObserver(forName: .init("NotifyLightDebug"), object: nil, queue: .main) { notification in
    print("NotifyLight Debug:", notification.userInfo ?? "")
}
```

### Performance Debugging

#### Memory Leaks
```bash
# iOS: Use Xcode Instruments
# Profile > Instruments > Leaks

# React Native: Use Flipper
npx react-native start
# Open Flipper and connect to your app
```

#### Network Debugging
```bash
# Use network proxy tools
# Charles Proxy, Proxyman, or mitmproxy

# Monitor all HTTP traffic between app and server
```

## Getting Help

### Log Collection

When reporting issues, include:

1. **Server logs:**
```bash
node test-server.js 2>&1 | tee server.log
```

2. **App logs:**
   - iOS: Xcode Console or device logs
   - Android: `adb logcat | grep -E "(ReactNativeJS|NotifyLight)"`

3. **System information:**
```bash
# Device info
node -v
npm -v
react-native --version
xcodebuild -version  # iOS
adb version  # Android
```

4. **Configuration:**
   - API URLs and keys (redacted)
   - SDK versions
   - Platform versions

### Common Debug Commands

```bash
# Server health check
curl -v http://localhost:3000/health

# Device registration test
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{"token":"test","platform":"ios","user_id":"debug"}' \
  -v http://localhost:3000/register-device

# Network connectivity
ping localhost
telnet localhost 3000

# Process monitoring
ps aux | grep -E "(node|Metro|Simulator)"
lsof -i :3000
```

### Community Resources

- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Check latest docs for updates
- **Stack Overflow**: Search for similar problems
- **Discord/Slack**: Join community channels for real-time help

Remember: When troubleshooting, always start with the simplest explanation and work your way up to more complex scenarios. Most issues are configuration or environment-related rather than actual bugs in the code.