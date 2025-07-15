# NotifyLight SDK Integration - Testing Instructions

## Overview
This document provides instructions for testing the NotifyLight SDK integration in the iOS test app.

## What Was Implemented

### 1. SDK Integration
- **NotifyLightSDK.swift**: Complete SDK implementation with:
  - Configuration management
  - Push notification authorization
  - In-app message handling
  - Event tracking
  - Device registration
  - SwiftUI integration

### 2. App Launch Message ("Hello World")
- **Location**: `NotifyLightTestApp.swift:38-42`
- **Trigger**: Automatically displays 2 seconds after app launch
- **Implementation**: 
  ```swift
  NotifyLight.shared.showInAppMessage(
      title: "Hello World",
      message: "Welcome to NotifyLight Test App! SDK integration is working."
  )
  ```

### 3. Portfolio Object Click Message ("Hello Again World")
- **Location**: `PortfolioView.swift:110-113`
- **Trigger**: When any portfolio asset (BTC, ETH, ADA, SOL) is tapped
- **Implementation**:
  ```swift
  NotifyLight.shared.showInAppMessage(
      title: "Hello Again World",
      message: "You clicked on \(asset.symbol)! This is triggered by portfolio object interaction."
  )
  ```

## Testing Steps

### Prerequisites
1. Ensure the NotifyLight backend is running on `http://localhost:3000`
2. Build and run the iOS app in Xcode simulator or device

### Test 1: App Launch Message
1. **Launch the app** from Xcode
2. **Watch console logs** for SDK initialization messages
3. **Wait 2 seconds** after splash screen appears
4. **Expected Result**: "Hello World" message appears as overlay with:
   - Title: "Hello World"
   - Message: "Welcome to NotifyLight Test App! SDK integration is working."
   - Dismiss button
   - Semi-transparent background

### Test 2: Portfolio Object Click Message
1. **Navigate to portfolio screen** (automatic after splash)
2. **Tap any crypto asset** (BTC, ETH, ADA, or SOL row)
3. **Expected Result**: "Hello Again World" message appears immediately with:
   - Title: "Hello Again World"
   - Message: "You clicked on [ASSET_SYMBOL]! This is triggered by portfolio object interaction."
   - Dismiss button
   - Semi-transparent background

### Test 3: Message Dismissal
1. **Trigger any message** (app launch or asset tap)
2. **Dismiss using one of these methods**:
   - Tap the "Dismiss" button
   - Tap the X button in top-right corner
   - Tap the semi-transparent background
   - Wait 5 seconds (auto-dismiss)
3. **Expected Result**: Message disappears with smooth animation

## Console Log Verification

### App Launch Logs
```
NotifyLightApp: ========== APP LAUNCHED ==========
NotifyLightApp: Initializing NotifyLight SDK Test App...
NotifyLight: Configuring SDK with URL: http://localhost:3000
NotifyLight: User ID: test-user-ios
NotifyLight: SDK configured successfully
NotifyLightApp: ✅ SDK configured successfully
NotifyLight: Requesting push notification authorization...
NotifyLight: Push authorization granted: true
NotifyLightApp: ✅ Push authorization status: 2
NotifyLight: Registering device...
NotifyLight: Device registered successfully with token: mock-device-token-[UUID]
NotifyLightApp: ✅ Device registered with token: mock-device-token-[UUID]
NotifyLight: Showing in-app message - Title: 'Hello World', Message: 'Welcome to NotifyLight Test App! SDK integration is working.'
```

### Portfolio Asset Tap Logs
```
PortfolioView: User tapped on BTC
PortfolioView: SDK Integration Point - Asset selected: BTC
NotifyLight: Tracking asset interaction: BTC
NotifyLight: Asset interaction tracked: [event details]
PortfolioView: SDK Integration Point - Showing 'Hello Again World' message...
NotifyLight: Showing in-app message - Title: 'Hello Again World', Message: 'You clicked on BTC! This is triggered by portfolio object interaction.'
```

## Troubleshooting

### Common Issues

#### 1. Messages Not Appearing
- **Check**: Console logs for SDK initialization
- **Fix**: Ensure SDK is properly configured
- **Verify**: `NotifyLight.shared.isConfigured` is true

#### 2. Console Logs Missing
- **Check**: Xcode console is open (Cmd+Shift+C)
- **Filter**: Search for "NotifyLight" in console
- **Verify**: Debug build configuration is selected

#### 3. Push Notifications Not Working
- **Check**: Device/simulator push notification settings
- **Note**: Real push notifications require APNs credentials
- **Workaround**: Use mock mode for testing

#### 4. App Crashes
- **Check**: All SDK files are added to Xcode project
- **Verify**: Import statements are correct
- **Debug**: Check for thread-safety issues

### Build Requirements
- iOS 15.0+ target
- Xcode 14.0+
- Swift 5.9+

## SDK Features Demonstrated

### 1. Configuration
- API URL and key setup
- User ID assignment
- Async initialization

### 2. Push Notifications
- Authorization request
- Device registration
- Token management

### 3. In-App Messages
- Message display with overlay
- Custom styling
- Auto-dismiss functionality
- User interaction handling

### 4. Event Tracking
- Screen view tracking
- Asset interaction tracking
- Custom event logging

### 5. SwiftUI Integration
- ObservableObject pattern
- Published properties
- View overlays
- Animation support

## Next Steps

### For Real Implementation
1. Replace mock SDK with actual NotifyLight SDK from GitHub
2. Configure real APNs credentials
3. Update API endpoints to production URLs
4. Implement proper error handling
5. Add comprehensive logging

### For Testing
1. Test with real push notifications
2. Verify with multiple users
3. Test message persistence
4. Validate analytics tracking
5. Performance testing

## Files Modified

### Core Integration Files
- `NotifyLightSDK.swift` - Complete SDK implementation
- `NotifyLightTestApp.swift` - App initialization and "Hello World" message
- `PortfolioView.swift` - "Hello Again World" message on asset tap

### Supporting Files
- `TestingInstructions.md` - This file
- All existing files maintained their structure

## Success Criteria
- ✅ SDK initializes without errors
- ✅ "Hello World" message appears on app launch
- ✅ "Hello Again World" message appears on asset tap
- ✅ Messages can be dismissed properly
- ✅ Console logs show proper SDK activity
- ✅ No crashes or memory leaks
- ✅ Smooth user experience maintained