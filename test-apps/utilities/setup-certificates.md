# Push Notification Certificate Setup

This guide walks you through setting up push notification certificates for APNs (iOS) and FCM (Android) with NotifyLight.

## APNs (Apple Push Notification Service) Setup

### Step 1: Create an App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **App IDs**
4. Click the **+** button to create a new App ID
5. Select **App** and click **Continue**
6. Fill in the details:
   - **Description**: NotifyLight Test App
   - **Bundle ID**: `com.yourcompany.notifylight-test` (or your preferred bundle ID)
7. Under **Capabilities**, enable **Push Notifications**
8. Click **Continue** and **Register**

### Step 2: Create APNs Certificate

1. In the Developer Portal, go to **Certificates** → **All**
2. Click the **+** button to create a new certificate
3. Under **Services**, select **Apple Push Notification service SSL (Sandbox & Production)**
4. Click **Continue**
5. Select your App ID from the dropdown
6. Click **Continue**
7. Follow the instructions to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** on your Mac
   - Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate From a Certificate Authority**
   - Enter your email address
   - Leave **CA Email Address** empty
   - Select **Saved to disk**
   - Click **Continue** and save the CSR file
8. Upload the CSR file and click **Continue**
9. Download the certificate (`.cer` file)

### Step 3: Install and Export Certificate

1. Double-click the downloaded `.cer` file to install it in Keychain Access
2. In Keychain Access, find your certificate under **My Certificates**
3. Right-click the certificate and select **Export**
4. Save as `.p12` format with a password
5. Convert to `.pem` format using OpenSSL:

```bash
# Convert certificate to PEM
openssl pkcs12 -in certificate.p12 -out certificate.pem -nodes

# Split into certificate and key files (optional)
openssl pkcs12 -in certificate.p12 -nokeys -out apns-cert.pem
openssl pkcs12 -in certificate.p12 -nocerts -nodes -out apns-key.pem
```

### Step 4: Configure NotifyLight Server

Add your APNs configuration to your NotifyLight server:

```bash
# Environment variables
export APNS_KEY_PATH="/path/to/apns-key.pem"
export APNS_CERT_PATH="/path/to/apns-cert.pem"
export APNS_BUNDLE_ID="com.yourcompany.notifylight-test"
export APNS_PRODUCTION=false  # Set to true for production
```

Or in your server configuration:

```javascript
// config.js
module.exports = {
  apns: {
    keyPath: process.env.APNS_KEY_PATH,
    certPath: process.env.APNS_CERT_PATH,
    bundleId: process.env.APNS_BUNDLE_ID,
    production: process.env.APNS_PRODUCTION === 'true'
  }
};
```

## FCM (Firebase Cloud Messaging) Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Create a project** or **Add project**
3. Enter project name: `notifylight-test`
4. Configure Google Analytics (optional)
5. Click **Create project**

### Step 2: Add Android App

1. In your Firebase project, click **Add app** → **Android**
2. Enter package name: `com.yourcompany.notifylight.test`
3. Enter app nickname: `NotifyLight Test`
4. Click **Register app**
5. Download `google-services.json` file
6. Click **Continue** through the setup steps

### Step 3: Get Server Key

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click the **Cloud Messaging** tab
3. Copy the **Server key** (legacy)

**Note**: Firebase recommends using the newer FCM HTTP v1 API with service account keys instead of legacy server keys.

### Step 4: Generate Service Account Key (Recommended)

1. In Firebase Console, go to **Project Settings** → **Service accounts**
2. Click **Generate new private key**
3. Download the JSON file
4. Store it securely on your server

### Step 5: Configure NotifyLight Server

Add your FCM configuration:

```bash
# Environment variables
export FCM_SERVER_KEY="your-fcm-server-key"
export FCM_SERVICE_ACCOUNT_PATH="/path/to/service-account.json"
```

Or in your server configuration:

```javascript
// config.js
module.exports = {
  fcm: {
    serverKey: process.env.FCM_SERVER_KEY,  // Legacy method
    serviceAccountPath: process.env.FCM_SERVICE_ACCOUNT_PATH  // Recommended
  }
};
```

## Testing Your Setup

### Test APNs Certificate

```bash
# Test APNs connection
openssl s_client -connect gateway.sandbox.push.apple.com:2195 \
  -cert apns-cert.pem -key apns-key.pem -CAfile entrust_2048_ca.pem

# Should show "Verify return code: 0 (ok)"
```

### Test FCM Configuration

```bash
# Test FCM with curl
curl -X POST \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_TOKEN",
    "notification": {
      "title": "Test",
      "body": "FCM test message"
    }
  }' \
  https://fcm.googleapis.com/fcm/send
```

### Using NotifyLight Test Tools

```bash
# Test with push-tester.sh
./test-apps/utilities/push-tester.sh health
./test-apps/utilities/push-tester.sh push "Test" "Hello from NotifyLight!"

# Test iOS app
cd test-apps/ios-native/NotifyLightTestiOS
open NotifyLightTestiOS.xcodeproj

# Test React Native app
cd test-apps/react-native/NotifyLightTestRN
npx react-native run-ios
npx react-native run-android
```

## Troubleshooting

### Common APNs Issues

1. **Invalid certificate**:
   - Ensure the certificate matches your bundle ID
   - Check that push notifications are enabled for your App ID
   - Verify the certificate is not expired

2. **Connection refused**:
   - Check if using correct gateway (sandbox vs production)
   - Verify certificate format and permissions

3. **Device token invalid**:
   - Ensure the device token is for the correct environment
   - Check that the app is properly signed

### Common FCM Issues

1. **Invalid server key**:
   - Verify the server key in Firebase Console
   - Ensure the key has proper permissions

2. **Registration token not valid**:
   - Check that the token is current and valid
   - Ensure the app package name matches Firebase configuration

3. **Authentication error**:
   - For service account: verify JSON file path and permissions
   - For server key: check that it's correctly configured

### Debug Logging

Enable debug logging in your test apps:

**iOS (Swift)**:
```swift
NotifyLight.Configuration(
  // ... other config
  enableDebugLogging: true
)
```

**React Native**:
```javascript
import { NotifyLight } from '@notifylight/react-native';

NotifyLight.configure({
  // ... other config
  enableDebugLogging: true
});
```

## Security Best Practices

1. **Never commit certificates or keys to version control**
2. **Use environment variables for sensitive configuration**
3. **Rotate certificates and keys regularly**
4. **Use production certificates only in production environments**
5. **Implement proper access controls for your push notification server**
6. **Monitor certificate expiration dates**

## Certificate Renewal

### APNs Certificate Renewal

APNs certificates expire after one year. To renew:

1. Create a new certificate following steps 2-3 above
2. Replace the old certificate files on your server
3. Update your server configuration
4. Test the new certificate before the old one expires

### FCM Configuration Updates

FCM server keys don't expire, but you should rotate them periodically:

1. Generate a new server key in Firebase Console
2. Update your server configuration
3. Test with the new key
4. Delete the old key once confirmed working

## Additional Resources

- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [NotifyLight Documentation](https://docs.notifylight.com)
- [APNs Certificate Troubleshooting](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_certificate-based_connection_to_apns)