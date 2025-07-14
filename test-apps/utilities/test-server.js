#!/usr/bin/env node

/**
 * NotifyLight Test Server
 * 
 * A lightweight mock server for testing NotifyLight SDKs without Docker.
 * Simulates the NotifyLight backend API for development and testing.
 */

const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// In-memory storage (for testing only)
const storage = {
  devices: new Map(),
  messages: new Map(),
  notifications: [],
  apiKeys: new Set(['test-api-key-123', 'demo-api-key'])
};

// Logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path} - ${req.ip}`);
  if (req.body && Object.keys(req.body).length > 0) {
    console.log('Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// API key validation middleware
const requireApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({
      success: false,
      message: 'API key is required'
    });
  }
  
  if (!storage.apiKeys.has(apiKey)) {
    return res.status(401).json({
      success: false,
      message: 'Invalid API key'
    });
  }
  
  req.apiKey = apiKey;
  next();
};

// Rate limiting middleware (simple version)
const rateLimiter = (maxRequests = 100, windowMs = 60000) => {
  const requests = new Map();
  
  return (req, res, next) => {
    const clientId = req.ip;
    const now = Date.now();
    
    if (!requests.has(clientId)) {
      requests.set(clientId, []);
    }
    
    const clientRequests = requests.get(clientId);
    
    // Remove old requests
    const validRequests = clientRequests.filter(time => now - time < windowMs);
    
    if (validRequests.length >= maxRequests) {
      return res.status(429).json({
        success: false,
        message: 'Rate limit exceeded'
      });
    }
    
    validRequests.push(now);
    requests.set(clientId, validRequests);
    
    next();
  };
};

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0-test',
    uptime: process.uptime(),
    environment: 'test'
  });
});

// API key validation
app.get('/validate', requireApiKey, (req, res) => {
  res.json({
    success: true,
    message: 'API key is valid',
    apiKey: req.apiKey.substring(0, 8) + '...'
  });
});

// Device registration
app.post('/register-device', requireApiKey, rateLimiter(50), (req, res) => {
  const { token, platform, user_id } = req.body;
  
  if (!token) {
    return res.status(400).json({
      success: false,
      message: 'Device token is required'
    });
  }
  
  if (!platform) {
    return res.status(400).json({
      success: false,
      message: 'Platform is required'
    });
  }
  
  const deviceId = uuidv4();
  const device = {
    id: deviceId,
    token,
    platform,
    user_id: user_id || null,
    registered_at: new Date().toISOString(),
    last_seen: new Date().toISOString(),
    api_key: req.apiKey
  };
  
  storage.devices.set(deviceId, device);
  
  console.log(`Device registered: ${deviceId} (${platform}) for user: ${user_id || 'anonymous'}`);
  
  res.json({
    success: true,
    device_id: deviceId,
    message: 'Device registered successfully'
  });
});

// Send notification
app.post('/notify', requireApiKey, rateLimiter(100), (req, res) => {
  const { title, message, users, type = 'push', actions, data } = req.body;
  
  if (!title && !message) {
    return res.status(400).json({
      success: false,
      message: 'Title or message is required'
    });
  }
  
  const notificationId = uuidv4();
  const notification = {
    id: notificationId,
    title: title || '',
    message: message || '',
    type,
    users: users || [],
    actions: actions || [],
    data: data || {},
    created_at: new Date().toISOString(),
    status: 'sent',
    api_key: req.apiKey
  };
  
  storage.notifications.push(notification);
  
  // For in-app messages, store in messages storage
  if (type === 'in-app') {
    const messageData = {
      id: notificationId,
      title: title || '',
      message: message || '',
      actions: actions || [],
      data: data || {},
      created_at: new Date().toISOString(),
      expires_at: null,
      is_read: false,
      users: users || []
    };
    
    storage.messages.set(notificationId, messageData);
    console.log(`In-app message created: ${notificationId} for users: ${JSON.stringify(users)}`);
  }
  
  // Simulate delivery
  const deliveredTo = [];
  if (users && users.length > 0) {
    for (const userId of users) {
      const userDevices = Array.from(storage.devices.values())
        .filter(device => device.user_id === userId);
      
      deliveredTo.push(...userDevices.map(device => ({
        device_id: device.id,
        user_id: userId,
        platform: device.platform,
        status: 'delivered'
      })));
    }
  }
  
  console.log(`Notification sent: ${notificationId} (${type}) to ${deliveredTo.length} devices`);
  
  res.json({
    success: true,
    notification_id: notificationId,
    delivered_to: deliveredTo,
    message: `${type} notification sent successfully`
  });
});

// Get in-app messages for user
app.get('/messages/:userId', requireApiKey, (req, res) => {
  const { userId } = req.params;
  const { active = 'true' } = req.query;
  
  const userMessages = Array.from(storage.messages.values())
    .filter(msg => {
      // Check if message is for this user
      const isForUser = msg.users.includes(userId) || msg.users.includes('all');
      
      // Check if message is active (not read and not expired)
      const isActive = active === 'true' ? !msg.is_read && (!msg.expires_at || new Date(msg.expires_at) > new Date()) : true;
      
      return isForUser && isActive;
    })
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  
  console.log(`Fetched ${userMessages.length} messages for user: ${userId}`);
  
  res.json({
    success: true,
    messages: userMessages,
    count: userMessages.length
  });
});

// Mark message as read
app.post('/messages/:messageId/read', requireApiKey, (req, res) => {
  const { messageId } = req.params;
  
  const message = storage.messages.get(messageId);
  if (!message) {
    return res.status(404).json({
      success: false,
      message: 'Message not found'
    });
  }
  
  message.is_read = true;
  message.read_at = new Date().toISOString();
  storage.messages.set(messageId, message);
  
  console.log(`Message marked as read: ${messageId}`);
  
  res.json({
    success: true,
    message: 'Message marked as read'
  });
});

// Get delivery logs
app.get('/logs/delivery', requireApiKey, (req, res) => {
  const { limit = 50, offset = 0 } = req.query;
  
  const logs = storage.notifications
    .slice(parseInt(offset), parseInt(offset) + parseInt(limit))
    .map(notification => ({
      id: notification.id,
      title: notification.title,
      type: notification.type,
      created_at: notification.created_at,
      status: notification.status,
      user_count: notification.users.length
    }));
  
  res.json({
    success: true,
    logs,
    total: storage.notifications.length,
    limit: parseInt(limit),
    offset: parseInt(offset)
  });
});

// Test utilities

// Create test messages
app.post('/test/create-messages', requireApiKey, (req, res) => {
  const { userId = 'test-user', count = 3 } = req.body;
  
  const testMessages = [
    {
      title: 'Welcome to NotifyLight!',
      message: 'Thanks for testing our SDK. This is your first in-app message.',
      actions: [
        { id: 'got-it', title: 'Got it!', style: 'primary' }
      ]
    },
    {
      title: 'Feature Update',
      message: 'We\'ve added new features to enhance your experience. Would you like to learn more?',
      actions: [
        { id: 'learn-more', title: 'Learn More', style: 'primary' },
        { id: 'later', title: 'Maybe Later', style: 'secondary' }
      ]
    },
    {
      title: 'Quick Survey',
      message: 'How would you rate your experience with NotifyLight?',
      actions: [
        { id: 'excellent', title: 'Excellent', style: 'primary' },
        { id: 'good', title: 'Good', style: 'secondary' },
        { id: 'poor', title: 'Needs Work', style: 'secondary' }
      ]
    },
    {
      title: 'Maintenance Notice',
      message: 'We\'ll be performing maintenance tonight from 2-4 AM. Some features may be temporarily unavailable.',
      actions: [
        { id: 'understood', title: 'Understood', style: 'primary' }
      ]
    },
    {
      title: 'Special Offer',
      message: 'Get 50% off your next purchase! Limited time offer.',
      actions: [
        { id: 'claim', title: 'Claim Offer', style: 'primary' },
        { id: 'dismiss', title: 'No Thanks', style: 'secondary' }
      ],
      data: {
        offer_code: 'SAVE50',
        expires: '2024-12-31'
      }
    }
  ];
  
  const createdMessages = [];
  
  for (let i = 0; i < Math.min(count, testMessages.length); i++) {
    const template = testMessages[i];
    const messageId = uuidv4();
    
    const message = {
      id: messageId,
      title: template.title,
      message: template.message,
      actions: template.actions,
      data: template.data || {},
      created_at: new Date(Date.now() - (i * 60000)).toISOString(), // Stagger creation times
      expires_at: null,
      is_read: false,
      users: [userId]
    };
    
    storage.messages.set(messageId, message);
    createdMessages.push(message);
  }
  
  console.log(`Created ${createdMessages.length} test messages for user: ${userId}`);
  
  res.json({
    success: true,
    messages: createdMessages,
    count: createdMessages.length
  });
});

// Clear test data
app.post('/test/clear', requireApiKey, (req, res) => {
  storage.devices.clear();
  storage.messages.clear();
  storage.notifications.length = 0;
  
  console.log('Test data cleared');
  
  res.json({
    success: true,
    message: 'Test data cleared'
  });
});

// Get server stats
app.get('/stats', requireApiKey, (req, res) => {
  res.json({
    success: true,
    stats: {
      devices: storage.devices.size,
      messages: storage.messages.size,
      notifications: storage.notifications.length,
      uptime: process.uptime(),
      memory: process.memoryUsage()
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log('\n🚀 NotifyLight Test Server Started');
  console.log(`📍 Server running on: http://localhost:${PORT}`);
  console.log(`🔑 Valid API keys: ${Array.from(storage.apiKeys).join(', ')}`);
  console.log('📊 Health check: GET /health');
  console.log('📱 Device registration: POST /register-device');
  console.log('🔔 Send notification: POST /notify');
  console.log('💬 Get messages: GET /messages/:userId');
  console.log('🧪 Create test messages: POST /test/create-messages');
  console.log('🗑️  Clear test data: POST /test/clear\n');
  
  // Show sample curl commands
  console.log('📝 Sample commands:');
  console.log('   Health check:');
  console.log(`   curl http://localhost:${PORT}/health`);
  console.log('\n   Send push notification:');
  console.log(`   curl -X POST http://localhost:${PORT}/notify \\`);
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -H "X-API-Key: test-api-key-123" \\');
  console.log('     -d \'{"title":"Test","message":"Hello!","users":["test-user"]}\'');
  console.log('\n   Create test messages:');
  console.log(`   curl -X POST http://localhost:${PORT}/test/create-messages \\`);
  console.log('     -H "Content-Type: application/json" \\');
  console.log('     -H "X-API-Key: test-api-key-123" \\');
  console.log('     -d \'{"userId":"test-user","count":3}\'');
  console.log('');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📪 Shutting down test server...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n📪 Shutting down test server...');
  process.exit(0);
});