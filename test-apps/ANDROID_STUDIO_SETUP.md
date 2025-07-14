# Android Studio Setup for NotifyLight Testing

This guide walks you through setting up Android Studio to test the NotifyLight React Native SDK on Android devices and emulators.

## Prerequisites

- **Android Studio** (latest stable version)
- **Node.js** 18+ and npm/yarn
- **Java Development Kit (JDK)** 11 or 17
- **React Native CLI** or **Expo CLI**

## Initial Setup

### 1. Install Android Studio

1. Download [Android Studio](https://developer.android.com/studio)
2. Run the installer and follow the setup wizard
3. Choose **Standard** installation type
4. Accept license agreements and let it download required components

### 2. Configure SDK and Tools

1. Open Android Studio
2. Go to **File** → **Settings** (or **Android Studio** → **Preferences** on macOS)
3. Navigate to **Appearance & Behavior** → **System Settings** → **Android SDK**
4. In the **SDK Platforms** tab, install:
   - **Android 13 (API 33)** - for latest testing
   - **Android 12 (API 31)** - for broader compatibility
   - **Android 10 (API 29)** - for older device support
5. In the **SDK Tools** tab, ensure these are installed:
   - **Android SDK Build-Tools** (latest)
   - **Android SDK Platform-Tools**
   - **Android SDK Tools**
   - **Android Emulator**
   - **Intel x86 Emulator Accelerator (HAXM)** (for Intel Macs)
   - **Google Play services**

### 3. Set Environment Variables

Add these to your shell profile (`.bashrc`, `.zshrc`, etc.):

```bash
# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS
# export ANDROID_HOME=$HOME/Android/Sdk        # Linux
# export ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk  # Windows

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

Reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

### 4. Verify Installation

```bash
# Check Android SDK
android --version

# Check ADB
adb version

# Check Java
java -version
javac -version
```

## Create Android Virtual Device (AVD)

### 1. Open AVD Manager

1. In Android Studio, click **Tools** → **AVD Manager**
2. Click **Create Virtual Device**

### 2. Choose Device

1. Select **Phone** category
2. Choose **Pixel 6** or **Pixel 7** (recommended for testing)
3. Click **Next**

### 3. Select System Image

1. Choose **API Level 33** (Android 13)
2. Select **x86_64** or **arm64-v8a** (based on your system)
3. Download if not already available
4. Click **Next**

### 4. Configure AVD

1. **AVD Name**: `NotifyLight_Test_API33`
2. **Startup orientation**: Portrait
3. Click **Advanced Settings** and configure:
   - **RAM**: 4096 MB
   - **Internal Storage**: 8192 MB
   - **SD Card**: 1024 MB
4. Click **Finish**

### 5. Start Emulator

1. Click the **Play** button next to your AVD
2. Wait for the emulator to boot completely
3. Verify it appears in `adb devices`:

```bash
adb devices
# Should show: emulator-5554    device
```

## Firebase Setup for Android

### 1. Create Firebase Project

If you haven't already created a Firebase project from the certificate setup guide:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project: `notifylight-test`
3. Enable Google Analytics (optional)

### 2. Add Android App

1. Click **Add app** → **Android**
2. **Package name**: `com.notifylighttestrn` (matches React Native app)
3. **App nickname**: `NotifyLight Test RN`
4. **Debug signing certificate SHA-1** (optional for testing)
5. Click **Register app**

### 3. Download Configuration

1. Download `google-services.json`
2. Place it in the React Native project:

```bash
cp google-services.json test-apps/react-native/NotifyLightTestRN/android/app/
```

## Configure React Native Project for Android

### 1. Navigate to Project

```bash
cd test-apps/react-native/NotifyLightTestRN
```

### 2. Install Dependencies

```bash
# Install npm dependencies
npm install

# Install iOS dependencies (if on macOS)
cd ios && pod install && cd ..

# For Android, ensure build tools are ready
cd android && ./gradlew clean && cd ..
```

### 3. Update Android Configuration

#### android/build.gradle
```gradle
buildscript {
    ext {
        buildToolsVersion = "33.0.0"
        minSdkVersion = 21
        compileSdkVersion = 33
        targetSdkVersion = 33
        ndkVersion = "23.1.7779620"
    }
    dependencies {
        classpath("com.android.tools.build:gradle:7.3.1")
        classpath("com.facebook.react:react-native-gradle-plugin")
        classpath("com.google.gms:google-services:4.3.15")  // For Firebase
    }
}
```

#### android/app/build.gradle
```gradle
apply plugin: "com.android.application"
apply plugin: "com.facebook.react"
apply plugin: "com.google.gms.google-services"  // For Firebase

android {
    compileSdkVersion rootProject.ext.compileSdkVersion

    defaultConfig {
        applicationId "com.notifylighttestrn"
        minSdkVersion rootProject.ext.minSdkVersion
        targetSdkVersion rootProject.ext.targetSdkVersion
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }
}

dependencies {
    implementation "com.facebook.react:react-android"
    implementation 'com.google.firebase:firebase-messaging:23.1.2'
    implementation 'com.google.firebase:firebase-analytics:21.2.2'
    
    // For React Native Firebase
    implementation 'com.google.firebase:firebase-bom:31.5.0'
    implementation 'com.google.firebase:firebase-messaging'
}
```

#### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:name=".MainApplication"
        android:allowBackup="false"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@style/AppTheme">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/AppTheme">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>

        <!-- Firebase Messaging Service -->
        <service
            android:name=".NotifyLightFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>

        <!-- Default notification icon and color -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@drawable/ic_notification" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_color"
            android:resource="@color/colorAccent" />
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="@string/default_notification_channel_id" />
    </application>
</manifest>
```

## Running the App

### 1. Start Metro Server

```bash
cd test-apps/react-native/NotifyLightTestRN
npx react-native start
```

### 2. Run on Android

In a new terminal:

```bash
# Run on emulator or connected device
npx react-native run-android

# Or specify a specific device
npx react-native run-android --deviceId emulator-5554
```

### 3. Verify Installation

1. App should launch on the emulator/device
2. Check that the NotifyLight SDK initializes properly
3. Test device token generation
4. Verify push notification registration

## Testing Push Notifications

### 1. Get Device Token

1. Open the test app
2. Navigate to the device information section
3. Copy the FCM token displayed
4. Or check the logs for the token

### 2. Send Test Notification

Using the push-tester script:

```bash
# Set environment variables
export NOTIFYLIGHT_API_URL="http://10.0.2.2:3000"  # For emulator
export NOTIFYLIGHT_API_KEY="test-api-key-123"
export NOTIFYLIGHT_USER_ID="test-user-android"

# Send push notification
./test-apps/utilities/push-tester.sh push "Android Test" "Hello from Android!"
```

### 3. Using Firebase Console

1. Go to Firebase Console → Cloud Messaging
2. Click **Send your first message**
3. Enter notification details
4. Select **Send test message**
5. Enter your device token
6. Click **Test**

## Debugging

### 1. Enable USB Debugging

On your Android device:
1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times to enable Developer options
3. Go to **Settings** → **Developer options**
4. Enable **USB debugging**

### 2. Connect Physical Device

```bash
# Check connected devices
adb devices

# If device not recognized, restart ADB
adb kill-server
adb start-server
adb devices
```

### 3. View Logs

```bash
# View all logs
adb logcat

# Filter React Native logs
adb logcat | grep -E "(ReactNativeJS|NotifyLight)"

# View crash logs
adb logcat | grep -E "(AndroidRuntime|FATAL)"
```

### 4. Common Issues

#### Build Failures

```bash
# Clean and rebuild
cd android
./gradlew clean
cd ..
npx react-native run-android
```

#### Metro Connection Issues

```bash
# Reset Metro cache
npx react-native start --reset-cache
```

#### Emulator Not Starting

```bash
# Start emulator from command line
emulator -avd NotifyLight_Test_API33

# Or with specific settings
emulator -avd NotifyLight_Test_API33 -no-snapshot-load
```

## Performance Testing

### 1. Enable Performance Monitoring

Add to `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.firebase:firebase-perf:20.3.2'
}
```

### 2. Monitor App Performance

1. Use Android Studio Profiler
2. Monitor CPU, Memory, and Network usage
3. Test notification delivery performance
4. Check battery usage impact

## Production Considerations

### 1. ProGuard Configuration

For release builds, add to `android/app/proguard-rules.pro`:

```proguard
# NotifyLight
-keep class com.notifylight.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
```

### 2. Signing Configuration

Configure signing for release builds in `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            storeFile file('your-release-key.keystore')
            storePassword 'your-store-password'
            keyAlias 'your-key-alias'
            keyPassword 'your-key-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled enableProguardInReleaseBuilds
            proguardFiles getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro"
        }
    }
}
```

## Additional Resources

- [React Native Environment Setup](https://reactnative.dev/docs/environment-setup)
- [Android Developer Documentation](https://developer.android.com/docs)
- [Firebase for Android Setup](https://firebase.google.com/docs/android/setup)
- [React Native Firebase](https://rnfirebase.io/)
- [Android Studio User Guide](https://developer.android.com/studio/intro)