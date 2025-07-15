# NotifyLight Test App

A minimal iOS test application designed specifically for testing the NotifyLight SDK integration. This app provides a clean, EQX-branded interface with comprehensive logging for SDK development and testing.

## Purpose

This application serves as a **testbed for NotifyLight SDK integration** and is **NOT intended for production use**. It focuses on:

- **Comprehensive logging** of app lifecycle events
- **SDK integration points** marked throughout the codebase
- **Simple, clean UI** following EQX brand guidelines
- **Easy testing** of notification flows

## Features

- **Splash Screen**: EQX-branded splash with fade animation
- **Portfolio View**: Mock crypto portfolio with sample data
- **Extensive Logging**: All major events logged to console
- **SDK Integration Points**: Clearly marked locations for SDK calls
- **Clean Architecture**: Simple SwiftUI-based structure

## Requirements

- **iOS 15.0+**
- **Xcode 14.0+**
- **Swift 5.9+**

## Project Structure

```
NotifyLightTestApp/
├── NotifyLightTestApp.swift      # Main app entry point
├── SplashScreenView.swift        # Splash screen with EQX branding
├── PortfolioView.swift           # Main portfolio interface
├── Models.swift                  # Data models and mock data
└── README.md                     # This file
```

## Build & Run Instructions

### Option 1: Create Xcode Project in Existing Folder (Recommended)

1. **Open Xcode**
2. **Create New Project**:
   - Choose "iOS" → "App"
   - Product Name: `NotifyLightTestApp`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 15.0
   - **Important**: When choosing project location, navigate to `/Users/enanhoque/Documents/claude/notifylight/NotifyLightTestApp/`

3. **Replace Default Files**:
   - Delete the default `ContentView.swift` file
   - The other Swift files (`NotifyLightTestApp.swift`, `SplashScreenView.swift`, `PortfolioView.swift`, `Models.swift`) are already in the folder
   - Add these existing files to your Xcode project by dragging them into the project navigator

4. **Build and Run**:
   - Select your target device/simulator
   - Press `Cmd + R` to build and run

### Option 2: Create Project Elsewhere and Copy Files

1. **Create Xcode project** in any location you prefer
2. **Copy the Swift files** from `/Users/enanhoque/Documents/claude/notifylight/NotifyLightTestApp/` to your project folder
3. **Add files to Xcode** by dragging them into the project navigator
4. **Build and Run**

### Option 2: Command Line

```bash
# Navigate to project directory
cd NotifyLightTestApp

# Build for simulator
xcodebuild -scheme NotifyLightTestApp -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run on simulator
open -a Simulator
xcodebuild -scheme NotifyLightTestApp -destination 'platform=iOS Simulator,name=iPhone 15' run
```

## Viewing Console Logs

### In Xcode

1. **Run the app** from Xcode (`Cmd + R`)
2. **Open Console**:
   - Window → Console (or `Cmd + Shift + C`)
   - View → Debug Area → Activate Console
3. **Filter logs**: Search for "NotifyLightApp" to see app-specific logs

### Using Console.app (macOS)

1. **Open Console.app** (found in Applications/Utilities)
2. **Select your device** from the sidebar
3. **Filter by process**: Search for "NotifyLightTestApp"
4. **View real-time logs** as you interact with the app

### Using Terminal

```bash
# View device logs (replace with your device UDID)
xcrun devicectl list devices
xcrun devicectl logs stream --device YOUR_DEVICE_UDID | grep "NotifyLightApp"

# View simulator logs
xcrun simctl spawn booted log stream --predicate 'processImagePath ENDSWITH "NotifyLightTestApp"'
```

## SDK Integration Points

The app includes clearly marked SDK integration points with detailed logging:

### App Lifecycle Events

- **App Launch**: `NotifyLightTestApp.swift:init()`
- **App Foreground**: `NotifyLightTestApp.swift:onAppear`
- **Splash Screen**: `SplashScreenView.swift:onAppear/onDisappear`
- **Portfolio Load**: `PortfolioView.swift:onAppear`

### User Interaction Events

- **Asset Selection**: `PortfolioView.swift:AssetRowView.onTapGesture`
- **Screen Transitions**: Throughout view lifecycle methods

### Example SDK Integration

```swift
// Example: Initialize SDK
NotifyLight.shared.configure(apiKey: "your-api-key", userId: "test-user")

// Example: Request push permissions
NotifyLight.shared.requestPushPermissions()

// Example: Check for messages
NotifyLight.shared.checkForInAppMessages()

// Example: Track events
NotifyLight.shared.trackScreenView(screen: "portfolio")
```

## Mock Data

The app includes sample crypto portfolio data:

- **Bitcoin (BTC)**: 0.5 BTC at $43,250
- **Ethereum (ETH)**: 2.5 ETH at $2,650
- **Cardano (ADA)**: 1,500 ADA at $0.48
- **Solana (SOL)**: 25 SOL at $105.50

To modify mock data, edit the `cryptoAssets` array in `Models.swift`.

## Understanding the Logs

### Log Format

All logs follow the pattern:
```
[ViewName]: [Log Level] - [Message]
```

### Key Log Categories

- **App Launch**: Initialization and SDK setup
- **View Lifecycle**: Screen appearances and transitions
- **User Interactions**: Taps, navigation, selections
- **Data Loading**: Mock data initialization
- **SDK Integration Points**: Marked locations for SDK calls

### Example Log Output

```
NotifyLightApp: ========== APP LAUNCHED ==========
NotifyLightApp: Initializing NotifyLight SDK Test App...
NotifyLightApp: SDK Integration Point - App delegate setup complete
SplashScreenView: ========== SPLASH SCREEN LOADED ==========
SplashScreenView: Starting fade-in animation...
SplashScreenView: SDK Integration Point - Early app initialization during splash...
PortfolioView: ========== PORTFOLIO VIEW LOADED ==========
PortfolioView: Loading portfolio data...
PortfolioView: SDK Integration Point - Checking for in-app messages on portfolio load...
```

## Testing Workflow

1. **Launch the app** and monitor console output
2. **Observe splash screen** transition and logging
3. **Interact with portfolio** items to trigger events
4. **Look for SDK integration points** in console logs
5. **Add actual SDK calls** at marked integration points

## Troubleshooting

### Common Issues

**No logs appearing**:
- Ensure you're filtering for "NotifyLightApp" in console
- Check that the app is running in debug mode
- Verify console is capturing device/simulator logs

**Build errors**:
- Ensure minimum iOS version is set to 15.0
- Check that all Swift files are added to target
- Verify no syntax errors in copied code

**Simulator not responding**:
- Reset simulator: Device → Erase All Content and Settings
- Restart Xcode and simulator
- Check available disk space

### Getting Help

This is a test application for SDK development. For issues:

1. Check console logs for specific error messages
2. Verify all files are correctly added to Xcode project
3. Ensure proper iOS/Xcode versions are being used
4. Test on different devices/simulators if needed

## Next Steps

1. **Integrate actual NotifyLight SDK** at marked integration points
2. **Replace mock data** with real portfolio data if needed
3. **Add push notification handling** for testing
4. **Implement in-app message display** for testing
5. **Test notification flows** using the setup verification script

This test app provides a solid foundation for comprehensive NotifyLight SDK testing with full visibility into app lifecycle events and user interactions.