# 🚀 NotifyLight

> **Open source, self-hosted notification infrastructure**  
> Send push notifications and in-app messages with complete control over your data.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Node.js](https://img.shields.io/badge/Node.js-16%2B-green.svg)](https://nodejs.org/)
[![React Native](https://img.shields.io/badge/React%20Native-0.70%2B-blue.svg)](https://reactnative.dev/)
[![iOS](https://img.shields.io/badge/iOS-13%2B-black.svg)](https://developer.apple.com/ios/)
[![Android](https://img.shields.io/badge/Android-API%2021%2B-green.svg)](https://developer.android.com/)

## ⚡ Quick Start

**From zero to sending your first push notification in 10 minutes:**

```bash
# 1. Clone and deploy
git clone https://github.com/e88-eqx/NotifyLight
cd NotifyLight
cp .env.example .env
docker-compose up -d

# 2. Send your first notification
curl -X POST http://localhost:3000/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "🎉 It works!",
    "message": "Your first NotifyLight notification",
    "users": ["test-user"]
  }'
```

📖 **[Read the complete 10-minute quickstart guide →](QUICKSTART.md)**

## 🎯 Why NotifyLight?

- **🔒 Your Data, Your Control** - Self-hosted, no vendor lock-in
- **💰 Zero Monthly Fees** - No per-notification pricing or user limits  
- **⚡ 2-Hour Implementation** - From setup to production in hours, not weeks
- **🌍 Cross-Platform** - iOS, Android, React Native, and web support
- **🛠️ Developer-First** - Clean APIs, comprehensive docs, TypeScript support
- **📈 Production Ready** - Scales from 10 to 10 million users

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Your App      │    │  NotifyLight     │    │  Push Services  │
│                 │    │                  │    │                 │
│  ┌─────────────┐│    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│  │    SDK      ││────┤ │  REST API    │ │────┤ │    APNs     │ │
│  └─────────────┘│    │ └──────────────┘ │    │ │     FCM     │ │
│                 │    │ ┌──────────────┐ │    │ └─────────────┘ │
│                 │    │ │   Database   │ │    │                 │
│                 │    │ │   (SQLite)   │ │    │                 │
│                 │    │ └──────────────┘ │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🚀 Features

### Core Features
- ✅ **Push Notifications** - iOS (APNs) and Android (FCM)
- ✅ **In-App Messages** - Rich, native UI components
- ✅ **User Targeting** - Send to specific users or broadcast
- ✅ **Message Actions** - Interactive buttons and deep linking
- ✅ **Delivery Tracking** - Real-time delivery status and analytics
- ✅ **Batch Operations** - Send to thousands of users efficiently

### Platform Support
- ✅ **React Native SDK** - iOS and Android support
- ✅ **Native iOS SDK** - Swift Package Manager integration
- ✅ **Native Android SDK** - Coming in Stage 2
- ✅ **Web SDK** - Coming in Stage 2
- ✅ **REST API** - Use from any platform or language

### DevOps & Operations
- ✅ **Docker Deployment** - One-command setup
- ✅ **SQLite Database** - Zero-config persistence (scales to 10K+ users)
- ✅ **PostgreSQL Support** - Enterprise-scale database option
- ✅ **Health Monitoring** - Built-in health checks and metrics
- ✅ **Rate Limiting** - Protect against abuse
- ✅ **CORS Support** - Frontend integration ready

## 📱 SDK Integration

### React Native

```bash
npm install @notifylight/react-native
```

```javascript
import { NotifyLight } from '@notifylight/react-native';

// Configure
NotifyLight.configure({
  apiUrl: 'https://your-notifylight-server.com',
  apiKey: 'your-api-key',
  userId: 'user-123'
});

// Request permissions and register
await NotifyLight.requestPermissions();
await NotifyLight.registerDevice();
```

### Native iOS (Swift)

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/e88-eqx/NotifyLight", from: "1.0.0")
]
```

```swift
import NotifyLight

// Configure
let config = NotifyLight.Configuration(
    apiUrl: URL(string: "https://your-server.com")!,
    apiKey: "your-api-key",
    userId: "user-123"
)

try await NotifyLight.shared.configure(with: config)
```

## 🛠️ API Examples

### Send Push Notification

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Breaking News",
    "message": "Something important happened!",
    "users": ["user-1", "user-2"],
    "type": "push",
    "data": {
      "url": "https://example.com/news/123",
      "priority": "high"
    }
  }'
```

### Send In-App Message

```bash
curl -X POST https://your-server.com/notify \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "title": "Update Available",
    "message": "Version 2.0 is now available with new features!",
    "users": ["user-123"],
    "type": "in-app",
    "actions": [
      {"id": "update", "title": "Update Now", "style": "primary"},
      {"id": "later", "title": "Later", "style": "secondary"}
    ]
  }'
```

### Register Device

```bash
curl -X POST https://your-server.com/register-device \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{
    "token": "device-push-token",
    "platform": "ios",
    "user_id": "user-123"
  }'
```

## 📊 Monitoring & Analytics

```bash
# Health check
curl https://your-server.com/health

# Server statistics
curl -H "X-API-Key: your-api-key" \
     https://your-server.com/stats

# Delivery logs
curl -H "X-API-Key: your-api-key" \
     https://your-server.com/logs/delivery
```

## 🧪 Testing & Development

### Verification Script

```bash
# Run comprehensive setup verification
./setup-verify.sh -v -p

# Expected output:
# ✅ Docker: Running (24.0.5)
# ✅ API Server: Responding (127ms)
# ✅ Database: Connected (SQLite, 150 devices)
# ✅ All tests passed! Ready to send notifications.
```


## 🔧 Configuration

### Environment Variables

```bash
# Required
API_KEY=your-super-secret-api-key
PORT=3000

# Push Services
APNS_KEY_PATH=./credentials/apns-key.p8
APNS_KEY_ID=XXXXXXXXXX
APNS_TEAM_ID=YYYYYYYYYY
APNS_BUNDLE_ID=com.yourapp.bundleid

FCM_SERVICE_ACCOUNT_PATH=./credentials/fcm-service-account.json

# Database (optional)
DATABASE_URL=sqlite:./data/notifylight.db
# DATABASE_URL=postgresql://user:pass@localhost/notifylight

# Development
NODE_ENV=production
ENABLE_MOCK_PUSH=false
LOG_LEVEL=info
```

### Docker Deployment

```yaml
# docker-compose.yml
version: '3.8'
services:
  notifylight:
    build: .
    ports:
      - "3000:3000"
    environment:
      - API_KEY=${API_KEY}
      - APNS_KEY_PATH=${APNS_KEY_PATH}
      - FCM_SERVICE_ACCOUNT_PATH=${FCM_SERVICE_ACCOUNT_PATH}
    volumes:
      - ./data:/app/data
      - ./credentials:/app/credentials
```

## 📈 Scaling

### Development (SQLite)
- **Users**: Up to 10,000
- **Notifications**: 100/second
- **Storage**: Single file database
- **Setup**: Zero configuration

### Production (PostgreSQL)
- **Users**: Millions
- **Notifications**: 1,000+/second  
- **Storage**: Distributed database
- **Setup**: 30-minute migration

```bash
# Migrate to PostgreSQL
npm run migrate:postgresql
```

## 🔒 Security

- **API Key Authentication** - Secure access control
- **Rate Limiting** - Protection against abuse
- **Input Validation** - SQL injection and XSS protection
- **CORS Configuration** - Controlled frontend access
- **Certificate Management** - Secure APNs/FCM credentials
- **No Data Collection** - Your data stays with you

## 📚 Documentation

- **[10-Minute Quickstart](QUICKSTART.md)** - Get started immediately
- **[API Reference](docs/api-reference.md)** - Complete API documentation
- **[SDK Guides](docs/sdk/)** - Platform-specific integration guides
- **[Deployment Guide](docs/deployment.md)** - Production deployment
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Contributing](CONTRIBUTING.md)** - How to contribute to NotifyLight

## 🗺️ Roadmap

### ✅ Stage 1: MVP (Complete)
- Core notification server
- SQLite database
- REST API
- Basic monitoring

### ✅ Stage 2: SDKs (Complete) 
- React Native SDK
- Native iOS SDK
- Comprehensive documentation

### 🚧 Stage 3: Production Features (In Progress)
- PostgreSQL support
- Advanced analytics
- Webhook support
- Admin dashboard

### 📋 Stage 4: Enterprise (Planned)
- High availability setup
- Advanced user segmentation
- A/B testing framework
- Performance monitoring

## 🤝 Contributing

We welcome contributions! NotifyLight is built for the developer community.

```bash
# Setup development environment
git clone https://github.com/e88-eqx/NotifyLight
cd NotifyLight
npm install
docker-compose up -d

# Run tests
npm test
./setup-verify.sh -v

# Make your changes and submit a PR!
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙋 Support

- **📖 Documentation**: Complete guides and API reference
- **🐛 Issues**: [GitHub Issues](https://github.com/e88-eqx/NotifyLight/issues)
- **💬 Discussions**: [GitHub Discussions](https://github.com/e88-eqx/NotifyLight/discussions)
- **📧 Email**: support@notifylight.dev

## ⭐ Show Your Support

If NotifyLight helps you build better apps, please give us a star! ⭐

---

**Built with ❤️ for developers who value control and simplicity.**

*NotifyLight: Your notifications, your infrastructure, your way.*
