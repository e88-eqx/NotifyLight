# NotifyLight Testing Guide

Complete testing procedures for verifying NotifyLight SDK integration and functionality across all platforms.

## Overview

This guide covers comprehensive testing of:
- **Backend Server**: Core API functionality
- **React Native SDK**: iOS and Android implementations
- **Native iOS SDK**: Swift package integration
- **End-to-End Workflows**: Complete notification delivery chains

## Quick Start Testing

### 1. Start Test Server

```bash
# Start the mock NotifyLight server
cd test-apps/utilities
node test-server.js

# Should show:
# 🚀 NotifyLight Test Server Started
# 📍 Server running on: http://localhost:3000
```

### 2. Verify Server Health

```bash
# Test server health
curl http://localhost:3000/health

# Expected response:
# {
#   "status": "ok",
#   "timestamp": "2024-01-01T00:00:00.000Z",
#   "version": "1.0.0-test",
#   "uptime": 1.234,
#   "environment": "test"
# }
```

### 3. Run Push Tester

```bash
# Make executable and run health check
chmod +x test-apps/utilities/push-tester.sh
./test-apps/utilities/push-tester.sh health

# Run comprehensive test suite
./test-apps/utilities/push-tester.sh suite
```

## Backend API Testing

### Core Endpoints

#### Health Check
```bash
curl http://localhost:3000/health
```
**Expected**: `200 OK` with server status

#### API Key Validation
```bash
curl -H "X-API-Key: test-api-key-123" \
     http://localhost:3000/validate
```
**Expected**: `200 OK` with validation confirmation

#### Device Registration
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{
    "token": "test-device-token-123",
    "platform": "ios",
    "user_id": "test-user"
  }' \
  http://localhost:3000/register-device
```
**Expected**: `200 OK` with device ID

#### Send Push Notification
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{
    "title": "Test Notification",
    "message": "This is a test push notification",
    "users": ["test-user"],
    "type": "push"
  }' \
  http://localhost:3000/notify
```
**Expected**: `200 OK` with notification ID

#### Send In-App Message
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{
    "title": "Welcome!",
    "message": "This is a test in-app message",
    "users": ["test-user"],
    "type": "in-app",
    "actions": [
      {"id": "ok", "title": "OK", "style": "primary"},
      {"id": "later", "title": "Later", "style": "secondary"}
    ]
  }' \
  http://localhost:3000/notify
```
**Expected**: `200 OK` with message ID

### Test Data Management

#### Create Test Messages
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{
    "userId": "test-user",
    "count": 5
  }' \
  http://localhost:3000/test/create-messages
```

#### Get User Messages
```bash
curl -H "X-API-Key: test-api-key-123" \
     http://localhost:3000/messages/test-user
```

#### Clear Test Data
```bash
curl -X POST \
  -H "X-API-Key: test-api-key-123" \
  http://localhost:3000/test/clear
```

## React Native SDK Testing

### Setup and Launch

#### iOS Testing
```bash
cd test-apps/react-native/NotifyLightTestRN

# Install dependencies
npm install
cd ios && pod install && cd ..

# Start Metro
npx react-native start

# Run on iOS (new terminal)
npx react-native run-ios
```

#### Android Testing
```bash
# Start Android emulator first
emulator -avd NotifyLight_Test_API33

# Run on Android
npx react-native run-android
```

### SDK Integration Tests

#### 1. Initialization Test
- **Action**: Launch app
- **Expected**: 
  - SDK initializes successfully
  - Debug logs show "NotifyLight initialized"
  - Status indicator shows "Connected"

#### 2. Device Registration Test
- **Action**: Tap "Register Device"
- **Expected**:
  - Device token obtained
  - Registration API call succeeds
  - Token displayed in app (first 20 chars)

#### 3. Permission Request Test
- **Action**: Tap "Request Permissions"
- **Expected**:
  - iOS: System permission dialog appears
  - Android: Notification permission granted
  - Status indicator updates

#### 4. Push Notification Test
- **Action**: 
  1. Use push-tester: `./push-tester.sh push "RN Test" "Hello React Native!"`
  2. Or send via app's "Send Test Push" button
- **Expected**:
  - Push notification appears in system tray
  - App handles foreground/background states
  - Notification logged in app

#### 5. In-App Message Test
- **Action**: 
  1. Tap "Check for Messages"
  2. Or use: `./push-tester.sh message "RN Message" "Test in-app message"`
- **Expected**:
  - In-app message overlay appears
  - Actions work correctly
  - Message dismissed properly

#### 6. Network Connectivity Test
- **Action**: Tap "Test Network"
- **Expected**:
  - Server health check succeeds
  - API connectivity confirmed
  - Network status updated

### Performance Tests

#### Memory Usage
- Monitor with Flipper or React Native Debugger
- Check for memory leaks during notification handling
- Verify cleanup when app backgrounded

#### Battery Impact
- Run extended tests (1+ hours)
- Monitor battery consumption
- Ensure efficient background processing

## Native iOS SDK Testing

### Setup and Launch

```bash
cd test-apps/ios-native/NotifyLightTestiOS

# Open in Xcode
open NotifyLightTestiOS.xcodeproj

# Or run from command line
xcodebuild -project NotifyLightTestiOS.xcodeproj \
           -scheme NotifyLightTestiOS \
           -destination 'platform=iOS Simulator,name=iPhone 14' \
           build
```

### SDK Integration Tests

#### 1. Configuration Test
- **Action**: Launch app
- **Expected**:
  - SDK configured with test settings
  - User ID generated
  - API URL set to localhost:3000

#### 2. Token Retrieval Test
- **Action**: Tap "Get Token"
- **Expected**:
  - APNs token retrieved
  - Token displayed (truncated)
  - Test result marked as passed

#### 3. Message Fetching Test
- **Action**: 
  1. Create test messages: `./push-tester.sh create test-user-ios 3`
  2. Tap "Check Messages"
- **Expected**:
  - Messages fetched from server
  - Message count displayed
  - Messages appear in recent list

#### 4. Custom Message Test
- **Action**: Tap "Show Test Message"
- **Expected**:
  - In-app message appears with native iOS styling
  - Blur effect and animations work
  - Swipe/tap to dismiss functions

#### 5. Badge Management Test
- **Action**: Tap "Badge Test"
- **Expected**:
  - App badge set to 5
  - Badge cleared after 1 second
  - Test marked as passed

#### 6. All Tests Suite
- **Action**: Tap "🧪 Run All Tests"
- **Expected**:
  - All tests execute sequentially
  - Progress logged in real-time
  - Final summary shows pass/fail status

### UI/UX Tests

#### In-App Message Styling
- Verify native iOS design language
- Test blur effects and transparency
- Check Dynamic Type support
- Verify dark mode compatibility

#### Accessibility
- Test with VoiceOver enabled
- Verify proper accessibility labels
- Check keyboard navigation
- Test Dynamic Type scaling

## Cross-Platform Testing

### Feature Parity

| Feature | React Native iOS | React Native Android | Native iOS |
|---------|------------------|---------------------|------------|
| Push Notifications | ✅ | ✅ | ✅ |
| In-App Messages | ✅ | ✅ | ✅ |
| Device Registration | ✅ | ✅ | ✅ |
| Message Actions | ✅ | ✅ | ✅ |
| Badge Management | ✅ | ✅ | ✅ |
| Background Handling | ✅ | ✅ | ✅ |
| Debug Logging | ✅ | ✅ | ✅ |

### Integration Testing

#### End-to-End Workflow
1. **Server**: Start test server
2. **Device**: Launch test app
3. **Registration**: Register device with server
4. **Push**: Send push notification via API
5. **Delivery**: Verify notification received
6. **In-App**: Send in-app message
7. **Display**: Verify message displayed correctly
8. **Action**: Test message actions
9. **Cleanup**: Clear test data

#### Multi-Device Testing
```bash
# Register multiple devices
./push-tester.sh create user-1 3
./push-tester.sh create user-2 2

# Send to multiple users
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{
    "title": "Multi-User Test",
    "message": "Testing multiple devices",
    "users": ["user-1", "user-2", "user-3"]
  }' \
  http://localhost:3000/notify
```

## Automated Testing

### Unit Tests

#### React Native
```bash
cd test-apps/react-native/NotifyLightTestRN
npm test
```

#### iOS (Swift)
```bash
cd test-apps/ios-native/NotifyLightTestiOS
xcodebuild test \
  -project NotifyLightTestiOS.xcodeproj \
  -scheme NotifyLightTestiOS \
  -destination 'platform=iOS Simulator,name=iPhone 14'
```

### Integration Test Scripts

#### Comprehensive Test Script
```bash
#!/bin/bash
# test-suite.sh

echo "🚀 Starting NotifyLight Test Suite"

# Start server
echo "📡 Starting test server..."
node test-apps/utilities/test-server.js &
SERVER_PID=$!
sleep 3

# Test server
echo "🔍 Testing server health..."
./test-apps/utilities/push-tester.sh health || exit 1

# Test API endpoints
echo "📋 Testing API endpoints..."
./test-apps/utilities/push-tester.sh suite || exit 1

# Cleanup
echo "🧹 Cleaning up..."
kill $SERVER_PID

echo "✅ Test suite completed successfully!"
```

### CI/CD Integration

#### GitHub Actions Example
```yaml
name: NotifyLight Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd test-apps/utilities
          npm install
      
      - name: Start test server
        run: |
          cd test-apps/utilities
          node test-server.js &
          sleep 3
      
      - name: Run API tests
        run: |
          chmod +x test-apps/utilities/push-tester.sh
          ./test-apps/utilities/push-tester.sh suite
```

## Load Testing

### Server Performance

#### Concurrent Users Test
```bash
# Install Apache Bench
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Test 100 concurrent requests
ab -n 1000 -c 100 -H "X-API-Key: test-api-key-123" \
   http://localhost:3000/health

# Test notification sending
ab -n 100 -c 10 -p push-data.json -T application/json \
   -H "X-API-Key: test-api-key-123" \
   http://localhost:3000/notify
```

#### Memory and CPU Monitoring
```bash
# Monitor server resources
top -p $(pgrep -f test-server.js)

# Or use htop for better visualization
htop -p $(pgrep -f test-server.js)
```

### Mobile App Performance

#### iOS Instruments
1. Open Xcode
2. Product → Profile
3. Select "Time Profiler" or "Allocations"
4. Run notification tests while profiling

#### Android Profiler
1. Open Android Studio
2. Run app with profiler enabled
3. Monitor CPU, Memory, and Network usage
4. Test notification scenarios

## Security Testing

### API Security

#### Invalid API Keys
```bash
# Test with invalid key
curl -H "X-API-Key: invalid-key" \
     http://localhost:3000/validate
# Expected: 401 Unauthorized
```

#### Rate Limiting
```bash
# Test rate limiting (adjust script for your limits)
for i in {1..150}; do
  curl -H "X-API-Key: test-api-key-123" \
       http://localhost:3000/health
done
# Expected: 429 Too Many Requests after limit
```

#### Input Validation
```bash
# Test malformed JSON
curl -X POST \
  -H "Content-Type: application/json" \
  -H "X-API-Key: test-api-key-123" \
  -d '{"invalid": json}' \
  http://localhost:3000/notify
# Expected: 400 Bad Request
```

### Mobile Security

#### Certificate Pinning (Production)
- Verify SSL/TLS certificate validation
- Test with self-signed certificates
- Ensure proper error handling

#### Data Storage
- Check that sensitive data isn't logged
- Verify secure storage of tokens
- Test data cleanup on app uninstall

## Regression Testing

### Version Compatibility

#### SDK Compatibility Matrix
| NotifyLight Server | React Native SDK | iOS SDK | Status |
|-------------------|------------------|---------|---------|
| 1.0.0 | 1.0.0 | 1.0.0 | ✅ |
| 1.0.0 | 0.9.x | 0.9.x | ⚠️ |
| 0.9.x | 1.0.0 | 1.0.0 | ❌ |

#### Breaking Changes Checklist
- [ ] API endpoint changes
- [ ] Response format changes
- [ ] Authentication method changes
- [ ] SDK initialization changes
- [ ] Notification payload format changes

### Test Data Sets

#### Standard Test Messages
```json
{
  "basic_push": {
    "title": "Basic Test",
    "message": "Simple push notification"
  },
  "rich_push": {
    "title": "Rich Notification",
    "message": "Notification with custom data",
    "data": {"type": "promotion", "id": "123"}
  },
  "action_message": {
    "title": "Action Required",
    "message": "Please choose an option",
    "actions": [
      {"id": "yes", "title": "Yes", "style": "primary"},
      {"id": "no", "title": "No", "style": "secondary"}
    ]
  }
}
```

## Documentation Testing

### README Accuracy
- [ ] Installation instructions work
- [ ] Code examples compile and run
- [ ] API documentation matches implementation
- [ ] Links are valid and accessible

### Tutorial Validation
- [ ] "Getting Started" tutorial works end-to-end
- [ ] Configuration examples are correct
- [ ] Troubleshooting steps resolve common issues

## Release Testing Checklist

### Pre-Release
- [ ] All automated tests pass
- [ ] Manual test scenarios completed
- [ ] Performance benchmarks met
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Breaking changes documented

### Release Validation
- [ ] Installation from package managers works
- [ ] Sample apps work with released version
- [ ] Migration guide tested (if applicable)
- [ ] Rollback procedure verified

### Post-Release
- [ ] Monitor crash reports
- [ ] Check performance metrics
- [ ] Verify user feedback
- [ ] Monitor API usage patterns

## Troubleshooting Common Issues

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions to common problems encountered during testing.