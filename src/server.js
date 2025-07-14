const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const db = require('./db');
const pushService = require('./services/pushService');
const { validateNotificationPayload, validateDevicePayload, sanitizeNotificationPayload } = require('./utils/validator');

// Load environment variables from .env file if it exists
try {
  require('fs').readFileSync('.env', 'utf8')
    .split('\n')
    .filter(line => line.includes('='))
    .forEach(line => {
      const [key, value] = line.split('=');
      if (key && value && !process.env[key]) {
        process.env[key] = value;
      }
    });
} catch (err) {
  // .env file doesn't exist, use environment variables or defaults
}

const app = express();
const PORT = process.env.PORT || 3000;
const API_KEY = process.env.API_KEY || 'default-api-key';

// CORS configuration
const corsOptions = {
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'X-API-Key']
};

// Rate limiting
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 100 // limit each IP to 100 requests per windowMs
});

// Separate rate limiter for message creation
const messageLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 10, // limit each IP to 10 message creations per minute
  message: {
    error: 'Too many message creation requests',
    message: 'Please wait before creating more messages'
  }
});

// Middleware
app.use(cors(corsOptions));
app.use(express.json());
app.use(limiter);

// API key validation middleware
const requireApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  
  if (!apiKey) {
    return res.status(401).json({ 
      error: 'API key missing', 
      message: 'Please provide X-API-Key header' 
    });
  }
  
  if (apiKey !== API_KEY) {
    return res.status(401).json({ 
      error: 'Invalid API key', 
      message: 'The provided API key is not valid' 
    });
  }
  
  next();
};

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const memUsage = process.memoryUsage();
    const uptime = process.uptime();
    const pushStatus = pushService.getStatus();
    const messageStats = await db.getMessageStats();
    
    res.json({
      status: 'healthy',
      uptime: `${Math.floor(uptime)}s`,
      memory: {
        used: `${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`,
        total: `${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`
      },
      services: {
        database: 'connected',
        pushService: {
          initialized: pushStatus.initialized,
          apns: pushStatus.apnsConfigured ? 'configured' : 'not configured',
          fcm: pushStatus.fcmConfigured ? 'configured' : 'not configured'
        }
      },
      metrics: {
        inAppMessages: messageStats
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Health check error:', error);
    res.status(500).json({
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Device registration endpoint
app.post('/register-device', requireApiKey, async (req, res) => {
  try {
    // Validate payload
    const validation = validateDevicePayload(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        error: 'Invalid payload',
        message: validation.errors.join(', ')
      });
    }

    const { token, platform, userId } = req.body;

    // Register device
    const device = await db.addDevice(token, platform, userId);
    
    res.json({
      success: true,
      message: 'Device registered successfully',
      device: {
        id: device.id,
        platform: device.platform,
        userId: device.userId
      },
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error registering device:', error);
    res.status(500).json({
      error: 'Device registration failed',
      message: error.message
    });
  }
});

// Main notification endpoint
app.post('/notify', requireApiKey, messageLimiter, async (req, res) => {
  try {
    // Validate payload
    const validation = validateNotificationPayload(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        error: 'Invalid payload',
        message: validation.errors.join(', ')
      });
    }

    // Sanitize and prepare payload
    const payload = sanitizeNotificationPayload(req.body);
    const notificationId = uuidv4();
    
    console.log('Notification processing started:', {
      id: notificationId,
      type: payload.type,
      timestamp: new Date().toISOString(),
      payload: payload,
      targetUsers: payload.users
    });

    let results = {};

    if (payload.type === 'in-app') {
      // Handle in-app messages
      results = await processInAppMessages(notificationId, payload);
    } else {
      // Handle push notifications (default behavior)
      results = await processPushNotifications(notificationId, payload);
    }
    
    console.log('Notification processing completed:', {
      id: notificationId,
      type: payload.type,
      ...results
    });
    
    // Return detailed response
    res.json({
      success: true,
      message: `${payload.type === 'in-app' ? 'In-app messages' : 'Push notifications'} processed successfully`,
      notificationId: notificationId,
      type: payload.type,
      results: results,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error processing notification:', error);
    res.status(500).json({
      error: 'Notification processing failed',
      message: error.message
    });
  }
});

// Helper function to process in-app messages
async function processInAppMessages(notificationId, payload) {
  const targetUsers = payload.users.includes('all') ? ['all'] : payload.users;
  
  let createdMessages = 0;
  let failedMessages = 0;
  const errors = [];

  if (targetUsers.includes('all')) {
    // For 'all' users, we need to get all registered user IDs
    const devices = await db.getDevices(['all']);
    const uniqueUserIds = [...new Set(devices.map(device => device.userId))];
    
    for (const userId of uniqueUserIds) {
      try {
        const messageId = uuidv4();
        await db.createInAppMessage(messageId, payload.title, payload.message, userId);
        createdMessages++;
      } catch (error) {
        console.error(`Failed to create in-app message for user ${userId}:`, error);
        failedMessages++;
        errors.push(`User ${userId}: ${error.message}`);
      }
    }
  } else {
    // Create messages for specific users
    for (const userId of targetUsers) {
      try {
        const messageId = uuidv4();
        await db.createInAppMessage(messageId, payload.title, payload.message, userId);
        createdMessages++;
      } catch (error) {
        console.error(`Failed to create in-app message for user ${userId}:`, error);
        failedMessages++;
        errors.push(`User ${userId}: ${error.message}`);
      }
    }
  }

  return {
    total: createdMessages + failedMessages,
    successful: createdMessages,
    failed: failedMessages,
    deliveryRate: (createdMessages + failedMessages) > 0 ? Math.round((createdMessages / (createdMessages + failedMessages)) * 100) : 0,
    errors: errors.length > 0 ? errors : undefined
  };
}

// Helper function to process push notifications
async function processPushNotifications(notificationId, payload) {
  // Fetch devices for target users
  const devices = await db.getDevices(payload.users);
  
  if (devices.length === 0) {
    throw new Error('No registered devices found for the specified users');
  }

  // Send notifications using push service
  const batchResult = await pushService.sendBatchNotifications(devices, payload, notificationId);
  
  // Log delivery results
  for (const result of batchResult.results) {
    const status = result.success ? 'sent' : 'failed';
    const errorMessage = result.success ? null : result.error;
    
    try {
      await db.logDelivery(notificationId, result.token, status, errorMessage);
    } catch (logError) {
      console.error('Failed to log delivery:', logError);
    }
  }

  return {
    total: batchResult.total,
    successful: batchResult.successful,
    failed: batchResult.failed,
    deliveryRate: batchResult.total > 0 ? Math.round((batchResult.successful / batchResult.total) * 100) : 0
  };
}

// Get messages for a user
app.get('/messages/:userId', requireApiKey, async (req, res) => {
  try {
    const { userId } = req.params;
    
    if (!userId || typeof userId !== 'string') {
      return res.status(400).json({
        error: 'Invalid user ID',
        message: 'User ID must be a valid string'
      });
    }

    // Get active messages for the user
    const messages = await db.getActiveMessagesForUser(userId);
    
    res.json({
      success: true,
      userId: userId,
      messages: messages.map(msg => ({
        id: msg.id,
        title: msg.title,
        message: msg.message,
        createdAt: msg.createdAt,
        status: msg.status
      })),
      count: messages.length,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({
      error: 'Failed to fetch messages',
      message: error.message
    });
  }
});

// Mark a message as read
app.post('/messages/:messageId/read', requireApiKey, async (req, res) => {
  try {
    const { messageId } = req.params;
    
    if (!messageId || typeof messageId !== 'string') {
      return res.status(400).json({
        error: 'Invalid message ID',
        message: 'Message ID must be a valid string'
      });
    }

    // Mark message as read
    const result = await db.markMessageAsRead(messageId);
    
    res.json({
      success: true,
      message: 'Message marked as read',
      messageId: messageId,
      readAt: result.readAt,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error marking message as read:', error);
    
    if (error.message.includes('not found') || error.message.includes('already read')) {
      res.status(404).json({
        error: 'Message not found',
        message: error.message
      });
    } else {
      res.status(500).json({
        error: 'Failed to mark message as read',
        message: error.message
      });
    }
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `${req.method} ${req.originalUrl} is not a valid endpoint`
  });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: 'Something went wrong processing your request'
  });
});

// Initialize database and start server
async function startServer() {
  try {
    // Initialize database
    await db.initDb();
    
    // Initialize push service
    await pushService.initialize();
    
    app.listen(PORT, () => {
      console.log(`NotifyLight server running on port ${PORT}`);
      console.log(`Health check: http://localhost:${PORT}/health`);
      console.log(`Device registration: POST http://localhost:${PORT}/register-device`);
      console.log(`Notifications: POST http://localhost:${PORT}/notify`);
      console.log(`User messages: GET http://localhost:${PORT}/messages/:userId`);
      console.log(`Mark as read: POST http://localhost:${PORT}/messages/:messageId/read`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\nShutting down gracefully...');
  try {
    await pushService.shutdown();
    db.close();
  } catch (error) {
    console.error('Error during shutdown:', error);
  }
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\nShutting down gracefully...');
  try {
    await pushService.shutdown();
    db.close();
  } catch (error) {
    console.error('Error during shutdown:', error);
  }
  process.exit(0);
});

startServer();