const apn = require('apn');
const admin = require('firebase-admin');
const fs = require('fs');
const { validatePushConfig } = require('../utils/validator');

class PushService {
  constructor() {
    this.apnProvider = null;
    this.fcmApp = null;
    this.initialized = false;
    this.config = {
      hasApns: false,
      hasFcm: false
    };
  }

  async initialize() {
    try {
      const configValidation = validatePushConfig();
      
      if (!configValidation.isValid) {
        console.warn('Push configuration warnings:', configValidation.errors);
      }
      
      this.config = {
        hasApns: configValidation.hasApns,
        hasFcm: configValidation.hasFcm
      };
      
      // Initialize APNs if configured
      if (this.config.hasApns) {
        await this.initializeApns();
      }
      
      // Initialize FCM if configured
      if (this.config.hasFcm) {
        await this.initializeFcm();
      }
      
      if (!this.config.hasApns && !this.config.hasFcm) {
        console.warn('No push notification services configured. Notifications will be logged only.');
      }
      
      this.initialized = true;
      console.log('Push service initialized successfully');
      
    } catch (error) {
      console.error('Failed to initialize push service:', error);
      throw error;
    }
  }

  async initializeApns() {
    try {
      const keyPath = process.env.APNS_KEY_PATH;
      
      // Check if key file exists
      if (!fs.existsSync(keyPath)) {
        throw new Error(`APNs key file not found at: ${keyPath}`);
      }
      
      const options = {
        token: {
          key: keyPath,
          keyId: process.env.APNS_KEY_ID,
          teamId: process.env.APNS_TEAM_ID
        },
        production: process.env.APNS_PRODUCTION === 'true'
      };
      
      this.apnProvider = new apn.Provider(options);
      console.log(`APNs initialized (${options.production ? 'production' : 'sandbox'} mode)`);
      
    } catch (error) {
      console.error('APNs initialization failed:', error.message);
      throw error;
    }
  }

  async initializeFcm() {
    try {
      const serviceAccount = {
        projectId: process.env.FCM_PROJECT_ID,
        privateKey: process.env.FCM_PRIVATE_KEY.replace(/\\n/g, '\n'),
        clientEmail: process.env.FCM_CLIENT_EMAIL
      };
      
      this.fcmApp = admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: serviceAccount.projectId
      });
      
      console.log('FCM initialized successfully');
      
    } catch (error) {
      console.error('FCM initialization failed:', error.message);
      throw error;
    }
  }

  async sendPushNotification(device, payload, notificationId) {
    if (!this.initialized) {
      throw new Error('Push service not initialized');
    }
    
    const maxRetries = 3;
    let lastError = null;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        let result;
        
        if (device.platform === 'ios' && this.config.hasApns) {
          result = await this.sendApnsNotification(device, payload);
        } else if (device.platform === 'android' && this.config.hasFcm) {
          result = await this.sendFcmNotification(device, payload);
        } else {
          // No push service configured for this platform
          console.log(`No push service configured for ${device.platform}, logging only`);
          return {
            success: true,
            platform: device.platform,
            token: device.token,
            attempt,
            message: 'Logged (no push service configured)'
          };
        }
        
        return {
          success: true,
          platform: device.platform,
          token: device.token,
          attempt,
          ...result
        };
        
      } catch (error) {
        lastError = error;
        console.error(`Push notification attempt ${attempt}/${maxRetries} failed for ${device.platform} device:`, error.message);
        
        // Don't retry for certain errors
        if (this.isNonRetryableError(error)) {
          break;
        }
        
        // Wait before retry (exponential backoff)
        if (attempt < maxRetries) {
          const delay = Math.pow(2, attempt) * 1000; // 2s, 4s, 8s
          await new Promise(resolve => setTimeout(resolve, delay));
        }
      }
    }
    
    return {
      success: false,
      platform: device.platform,
      token: device.token,
      attempt: maxRetries,
      error: lastError.message
    };
  }

  async sendApnsNotification(device, payload) {
    const notification = new apn.Notification();
    
    // Set notification content
    if (payload.title) {
      notification.title = payload.title;
    }
    if (payload.message) {
      notification.body = payload.message;
    }
    
    // Basic APNs settings
    notification.topic = process.env.APNS_BUNDLE_ID || 'com.notifylight.app';
    notification.sound = 'default';
    notification.badge = 1;
    
    // Send notification
    const result = await this.apnProvider.send(notification, device.token);
    
    // Check for failures
    if (result.failed && result.failed.length > 0) {
      const failure = result.failed[0];
      throw new Error(`APNs delivery failed: ${failure.error || failure.response}`);
    }
    
    return {
      messageId: 'apns-' + Date.now(),
      sent: result.sent.length,
      failed: result.failed.length
    };
  }

  async sendFcmNotification(device, payload) {
    const message = {
      token: device.token,
      notification: {},
      android: {
        priority: 'high',
        notification: {
          channel_id: 'default'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };
    
    // Set notification content
    if (payload.title) {
      message.notification.title = payload.title;
    }
    if (payload.message) {
      message.notification.body = payload.message;
    }
    
    // Send notification
    const messageId = await admin.messaging().send(message);
    
    return {
      messageId,
      status: 'sent'
    };
  }

  isNonRetryableError(error) {
    const nonRetryableErrors = [
      'InvalidRegistration',
      'MismatchSenderId',
      'NotRegistered',
      'BadDeviceToken',
      'DeviceTokenNotForTopic'
    ];
    
    return nonRetryableErrors.some(errorType => 
      error.message.includes(errorType) || 
      (error.code && error.code.includes(errorType))
    );
  }

  async sendBatchNotifications(devices, payload, notificationId, concurrencyLimit = 10) {
    if (!Array.isArray(devices) || devices.length === 0) {
      return {
        total: 0,
        successful: 0,
        failed: 0,
        results: []
      };
    }
    
    console.log(`Sending notifications to ${devices.length} devices (concurrency: ${concurrencyLimit})`);
    
    const results = [];
    const chunks = this.chunkArray(devices, concurrencyLimit);
    
    for (const chunk of chunks) {
      const chunkPromises = chunk.map(device => 
        this.sendPushNotification(device, payload, notificationId)
          .catch(error => ({
            success: false,
            platform: device.platform,
            token: device.token,
            error: error.message
          }))
      );
      
      const chunkResults = await Promise.all(chunkPromises);
      results.push(...chunkResults);
    }
    
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    
    console.log(`Batch notification complete: ${successful} successful, ${failed} failed`);
    
    return {
      total: devices.length,
      successful,
      failed,
      results
    };
  }

  chunkArray(array, chunkSize) {
    const chunks = [];
    for (let i = 0; i < array.length; i += chunkSize) {
      chunks.push(array.slice(i, i + chunkSize));
    }
    return chunks;
  }

  async shutdown() {
    if (this.apnProvider) {
      this.apnProvider.shutdown();
      console.log('APNs provider shutdown');
    }
    
    if (this.fcmApp) {
      await this.fcmApp.delete();
      console.log('FCM app shutdown');
    }
    
    this.initialized = false;
  }

  getStatus() {
    return {
      initialized: this.initialized,
      apnsConfigured: this.config.hasApns,
      fcmConfigured: this.config.hasFcm
    };
  }
}

module.exports = new PushService();