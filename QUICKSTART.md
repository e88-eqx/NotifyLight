# NotifyLight Quickstart - 10 Minutes to First Notification

> **The Promise**: From zero to sending your first push notification in exactly 10 minutes. No complex setup, no vendor lock-in, no monthly fees.

## Prerequisites (1 minute check)

Check these quickly before starting:

```bash
# ✅ Check Docker (required)
docker --version
# Expected: Docker version 20.0+ 

# ✅ Check Docker Compose (required)
docker-compose --version
# Expected: docker-compose version 1.29+

# ✅ Check Node.js (for testing)
node --version
# Expected: v16.0+ (for SDK testing)

# ✅ Check curl (for API testing)
curl --version
# Expected: curl 7.0+ (usually pre-installed)
```

**Missing something?**
- [Install Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Install Node.js](https://nodejs.org/) (choose LTS version)

---

## 1. Deploy Backend (2 minutes)

### Get NotifyLight
```bash
# Clone the repository
git clone https://github.com/notifylight/notifylight
cd notifylight

# Copy environment template
cp .env.example .env
```

### Configure Your API Key
```bash
# Edit .env file with your secure API key
echo "API_KEY=your-super-secret-api-key-$(date +%s)" > .env
echo "PORT=3000" >> .env
echo "NODE_ENV=production" >> .env
```

### Start Services
```bash
# Deploy with Docker Compose
docker-compose up -d

# Expected output:
# Creating network "notifylight_default" with the default driver
# Creating volume "notifylight_data" with local driver
# Creating notifylight_app_1 ... done
```

### Verify Deployment
```bash
# Check if services are running
docker-compose ps

# Expected output:
# Name                   Command               State           Ports
# notifylight_app_1   docker-entrypoint.sh node   Up      0.0.0.0:3000->3000/tcp

# Test the health endpoint
curl http://localhost:3000/health

# Expected output:
# {
#   "status": "healthy",
#   "uptime": 5,
#   "version": "1.0.0",
#   "database": "connected"
# }
```

**✅ Success Criteria**: `curl http://localhost:3000/health` returns `"status": "healthy"`

---

## 2. Quick Credential Setup (2 minutes)

Choose your platform and follow the quick setup:

### Option A: iOS (APNs) Setup

1. **Get your APNs certificate** (if you have one):
```bash
# Place your certificate files in the credentials directory
mkdir -p credentials
# Copy your .p8 key file or .pem certificate here
cp /path/to/your/AuthKey_XXXXXXXXXX.p8 credentials/apns-key.p8
```

2. **Configure APNs in .env**:
```bash
# Add to your .env file
echo "APNS_KEY_PATH=./credentials/apns-key.p8" >> .env
echo "APNS_KEY_ID=XXXXXXXXXX" >> .env  # Your 10-character key ID
echo "APNS_TEAM_ID=YYYYYYYYYY" >> .env  # Your 10-character team ID
echo "APNS_BUNDLE_ID=com.yourapp.bundleid" >> .env
```

### Option B: Android (FCM) Setup

1. **Get your FCM service account key**:
```bash
# Place your Firebase service account JSON file
mkdir -p credentials
cp /path/to/your/firebase-service-account.json credentials/fcm-service-account.json
```

2. **Configure FCM in .env**:
```bash
# Add to your .env file
echo "FCM_SERVICE_ACCOUNT_PATH=./credentials/fcm-service-account.json" >> .env
```

### Option C: Testing Mode (No Credentials)

For immediate testing without real push services:

```bash
# Add to your .env file
echo "ENABLE_MOCK_PUSH=true" >> .env
echo "MOCK_PUSH_DELAY=1000" >> .env  # Simulate 1-second delivery
```

### Apply Configuration
```bash
# Restart services to apply new configuration
docker-compose restart

# Wait for restart (usually 10-15 seconds)
sleep 15

# Verify configuration
curl http://localhost:3000/health
```

**✅ Success Criteria**: Health check still returns `"status": "healthy"` and shows your push service status.

---

## 3. Mobile Integration (3 minutes)

### React Native Integration (Pick A or B)

#### Option A: React Native - Quick Integration

1. **Install the SDK**:
```bash
# In your React Native project
npm install @notifylight/react-native

# For iOS
cd ios && pod install && cd ..
```

2. **Initialize in your App.js**:
```javascript
import { NotifyLight } from '@notifylight/react-native';

// Configure NotifyLight
NotifyLight.configure({
  apiUrl: 'http://localhost:3000',  // Use your server URL
  apiKey: 'your-super-secret-api-key-1234',  // Use your API key
  userId: 'test-user-123'
});

// Request permissions and register
const setupNotifications = async () => {
  try {
    // Request permissions
    const granted = await NotifyLight.requestPermissions();
    if (granted) {
      // Register device
      const deviceId = await NotifyLight.registerDevice();
      console.log('Device registered:', deviceId);
    }
  } catch (error) {
    console.error('Notification setup failed:', error);
  }
};

// Call this in your component
useEffect(() => {
  setupNotifications();
}, []);
```

#### Option B: Native iOS - Swift Integration

1. **Add to your Xcode project**:
```swift
// Add Package Dependency in Xcode:
// File > Add Package Dependencies
// URL: https://github.com/notifylight/ios-sdk
```

2. **Configure in AppDelegate.swift**:
```swift
import NotifyLight
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure NotifyLight
        let config = NotifyLight.Configuration(
            apiUrl: URL(string: "http://localhost:3000")!,
            apiKey: "your-super-secret-api-key-1234",
            userId: "test-user-ios"
        )
        
        Task {
            do {
                try await NotifyLight.shared.configure(with: config)
                print("NotifyLight configured successfully")
            } catch {
                print("NotifyLight configuration failed:", error)
            }
        }
        
        return true
    }
}
```

3. **Request permissions in your ViewController**:
```swift
import NotifyLight

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Task {
            do {
                let status = try await NotifyLight.shared.requestPushAuthorization()
                if status == .authorized {
                    print("Push notifications authorized")
                }
            } catch {
                print("Failed to request authorization:", error)
            }
        }
    }
}
```

**✅ Success Criteria**: App launches without errors and logs show "NotifyLight configured successfully"

---

## 4. Send Test Notifications (1 minute)

### Register a Test Device
```bash
# Register a test device with the API
curl -X POST http://localhost:3000/register-device \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-1234" \
  -d '{
    "token": "test-device-token-12345",
    "platform": "ios",
    "user_id": "test-user-123"
  }'

# Expected output:
# {
#   "success": true,
#   "device_id": "uuid-device-id",
#   "message": "Device registered successfully"
# }
```

### Send Your First Push Notification
```bash
# Send a push notification
curl -X POST http://localhost:3000/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-1234" \
  -d '{
    "title": "🎉 NotifyLight Works!",
    "message": "Congratulations! You just sent your first push notification.",
    "users": ["test-user-123"],
    "type": "push"
  }'

# Expected output:
# {
#   "success": true,
#   "notification_id": "uuid-notification-id",
#   "delivered_to": [
#     {
#       "device_id": "uuid-device-id",
#       "user_id": "test-user-123",
#       "platform": "ios",
#       "status": "delivered"
#     }
#   ]
# }
```

### Send an In-App Message
```bash
# Send an in-app message with actions
curl -X POST http://localhost:3000/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-1234" \
  -d '{
    "title": "Welcome to NotifyLight!",
    "message": "Choose your next step:",
    "users": ["test-user-123"],
    "type": "in-app",
    "actions": [
      {"id": "explore", "title": "Explore Features", "style": "primary"},
      {"id": "docs", "title": "Read Docs", "style": "secondary"}
    ]
  }'

# Expected output:
# {
#   "success": true,
#   "notification_id": "uuid-message-id",
#   "message": "in-app notification sent successfully"
# }
```

**✅ Success Criteria**: Both API calls return `"success": true`

---

## 5. Verify Success (1 minute)

### Check Your App
- **Push notification**: Should appear in device notification center
- **In-app message**: Should appear when app is opened (if implemented)

### Monitor Server Activity
```bash
# Check server logs
docker-compose logs -f

# Check device registration
curl -H "X-API-Key: your-super-secret-api-key-1234" \
     http://localhost:3000/stats

# Expected output showing your registered devices:
# {
#   "success": true,
#   "stats": {
#     "devices": 1,
#     "messages": 1,
#     "notifications": 2,
#     "uptime": 600
#   }
# }
```

### Test Message Retrieval (for in-app messages)
```bash
# Get messages for your test user
curl -H "X-API-Key: your-super-secret-api-key-1234" \
     http://localhost:3000/messages/test-user-123

# Expected output:
# {
#   "success": true,
#   "messages": [
#     {
#       "id": "uuid-message-id",
#       "title": "Welcome to NotifyLight!",
#       "message": "Choose your next step:",
#       "actions": [...],
#       "created_at": "2024-01-01T12:00:00.000Z"
#     }
#   ],
#   "count": 1
# }
```

**✅ Success Criteria**: 
- Notifications appear in your app/device
- Server stats show registered devices
- Messages can be retrieved via API

---

## 🎉 Congratulations!

**You've successfully deployed NotifyLight and sent your first notifications!**

### What You've Accomplished:
- ✅ Self-hosted notification server running
- ✅ Mobile SDK integrated
- ✅ Push notifications working
- ✅ In-app messages implemented
- ✅ Complete API access

### Total Time: **~10 minutes** ⏱️

---

## Monitoring Your Installation

### Health Monitoring
```bash
# Quick health check
curl http://localhost:3000/health

# Detailed health with metrics
curl -H "X-API-Key: your-super-secret-api-key-1234" \
     http://localhost:3000/stats
```

### Log Monitoring
```bash
# View real-time logs
docker-compose logs -f

# View last 100 lines
docker-compose logs --tail=100
```

### Database Inspection
```bash
# Access SQLite database directly
docker-compose exec app sqlite3 /app/data/notifylight.db

# Example queries:
# .tables                          -- List all tables
# SELECT * FROM devices LIMIT 5;   -- View registered devices
# SELECT * FROM notifications LIMIT 5; -- View sent notifications
# .quit                            -- Exit
```

### Performance Monitoring
```bash
# Check resource usage
docker stats notifylight_app_1

# Check disk usage
docker-compose exec app df -h
```

---

## Scaling Beyond MVP

### When to Scale
Your SQLite setup works great until:
- **10,000+ devices** registered
- **1000+ notifications per minute**
- **Multiple server instances** needed

### Quick PostgreSQL Migration (30 minutes)
```bash
# Update docker-compose.yml to include PostgreSQL
# Update .env with PostgreSQL connection
# Run migration script
# Zero downtime migration available!
```

**Migration guide**: See `docs/scaling-guide.md` when you're ready.

---

## Next Steps

### Production Checklist
- [ ] Use real APNs/FCM credentials (not mock mode)
- [ ] Set strong API keys and rotate regularly  
- [ ] Configure SSL/TLS with proper certificates
- [ ] Set up monitoring and alerting
- [ ] Configure backups for your database
- [ ] Review security settings

### Advanced Features
- **Scheduled notifications**: Send notifications at specific times
- **User segmentation**: Target specific user groups
- **Analytics**: Track delivery rates and engagement
- **Webhooks**: Get notified of delivery events
- **Admin dashboard**: Web UI for notification management

### SDK Features to Explore
- **Custom notification sounds** 
- **Rich media attachments**
- **Action buttons and deep linking**
- **Badge count management**
- **Silent notifications**
- **Notification categories**

---

## Troubleshooting

### Common Issues & Quick Fixes

#### Server Won't Start
```bash
# Check if port 3000 is already in use
lsof -i :3000

# Kill process using port
kill -9 $(lsof -t -i:3000)

# Or use different port
echo "PORT=3001" >> .env
docker-compose up -d
```

#### API Key Errors
```bash
# Verify your API key in .env
cat .env | grep API_KEY

# Test with the correct key
curl -H "X-API-Key: $(grep API_KEY .env | cut -d= -f2)" \
     http://localhost:3000/health
```

#### Mobile App Not Receiving Notifications
1. **Check device registration**:
```bash
curl -H "X-API-Key: your-api-key" http://localhost:3000/stats
```

2. **Verify push credentials** in `.env` file
3. **Check app permissions** (iOS Settings > Notifications)
4. **Test with mock mode first**:
```bash
echo "ENABLE_MOCK_PUSH=true" >> .env
docker-compose restart
```

#### Container Issues
```bash
# Restart services
docker-compose restart

# Rebuild containers
docker-compose down
docker-compose up --build -d

# Check container logs
docker-compose logs app
```

### Getting Help

- **Documentation**: Full docs at `docs/`
- **API Reference**: `docs/api-reference.md`
- **GitHub Issues**: Report bugs and get help
- **Community**: Join our Discord for real-time support

---

## Success! 🚀

You now have:
- **Self-hosted notification infrastructure** (no vendor lock-in)
- **Cross-platform SDK** (React Native + iOS + Android)
- **Complete API access** (send from any system)
- **Zero monthly fees** (runs on your infrastructure)
- **Production-ready foundation** (scales to millions of users)

**Ready to build something amazing with notifications!** 

---

*Made with ❤️ by the NotifyLight team. Open source, self-hosted, and designed for developers who value simplicity and control.*