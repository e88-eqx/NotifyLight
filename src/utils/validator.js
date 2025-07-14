// Payload validation utilities for NotifyLight

/**
 * Validates notification payload
 */
function validateNotificationPayload(payload) {
  const errors = [];
  
  // Basic structure validation
  if (!payload || typeof payload !== 'object') {
    errors.push('Payload must be a valid object');
    return { isValid: false, errors };
  }
  
  // Title and message validation
  if (!payload.title && !payload.message) {
    errors.push('Either title or message is required');
  }
  
  if (payload.title && typeof payload.title !== 'string') {
    errors.push('Title must be a string');
  }
  
  if (payload.message && typeof payload.message !== 'string') {
    errors.push('Message must be a string');
  }
  
  // Title length validation (iOS has limits)
  if (payload.title && payload.title.length > 200) {
    errors.push('Title must be 200 characters or less');
  }
  
  // Message length validation
  if (payload.message && payload.message.length > 2000) {
    errors.push('Message must be 2000 characters or less');
  }
  
  // Type validation (push or in-app)
  if (payload.type && !['push', 'in-app'].includes(payload.type)) {
    errors.push('Type must be "push" or "in-app"');
  }
  
  // Users array validation
  if (payload.users) {
    if (!Array.isArray(payload.users)) {
      errors.push('Users must be an array');
    } else if (payload.users.length === 0) {
      errors.push('Users array cannot be empty');
    } else {
      const invalidUsers = payload.users.filter(user => typeof user !== 'string');
      if (invalidUsers.length > 0) {
        errors.push('All user IDs must be strings');
      }
    }
  }
  
  // In-app specific validation
  if (payload.type === 'in-app') {
    if (!payload.title) {
      errors.push('Title is required for in-app messages');
    }
    if (!payload.message) {
      errors.push('Message is required for in-app messages');
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

/**
 * Validates device registration payload
 */
function validateDevicePayload(payload) {
  const errors = [];
  
  if (!payload || typeof payload !== 'object') {
    errors.push('Payload must be a valid object');
    return { isValid: false, errors };
  }
  
  // Required fields
  if (!payload.token || typeof payload.token !== 'string') {
    errors.push('Token is required and must be a string');
  }
  
  if (!payload.platform || typeof payload.platform !== 'string') {
    errors.push('Platform is required and must be a string');
  }
  
  if (!payload.userId || typeof payload.userId !== 'string') {
    errors.push('UserId is required and must be a string');
  }
  
  // Platform validation
  if (payload.platform && !['ios', 'android'].includes(payload.platform)) {
    errors.push('Platform must be "ios" or "android"');
  }
  
  // Token length validation (basic sanity check)
  if (payload.token && payload.token.length < 10) {
    errors.push('Token appears to be too short (minimum 10 characters)');
  }
  
  if (payload.token && payload.token.length > 1000) {
    errors.push('Token appears to be too long (maximum 1000 characters)');
  }
  
  // UserId validation
  if (payload.userId && payload.userId.length > 255) {
    errors.push('UserId must be 255 characters or less');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

/**
 * Sanitizes notification payload for safe processing
 */
function sanitizeNotificationPayload(payload) {
  const sanitized = {};
  
  if (payload.title) {
    sanitized.title = String(payload.title).trim().substring(0, 200);
  }
  
  if (payload.message) {
    sanitized.message = String(payload.message).trim().substring(0, 2000);
  }
  
  // Type handling (default to push for backward compatibility)
  sanitized.type = payload.type && ['push', 'in-app'].includes(payload.type) ? payload.type : 'push';
  
  if (payload.users && Array.isArray(payload.users)) {
    sanitized.users = payload.users
      .filter(user => typeof user === 'string' && user.trim().length > 0)
      .map(user => user.trim());
  } else {
    sanitized.users = ['all'];
  }
  
  // Add additional metadata
  sanitized.timestamp = new Date().toISOString();
  
  return sanitized;
}

/**
 * Validates environment variables for push services
 */
function validatePushConfig() {
  const errors = [];
  
  // APNs validation
  const hasApnsConfig = process.env.APNS_KEY_ID || process.env.APNS_TEAM_ID || process.env.APNS_KEY_PATH;
  if (hasApnsConfig) {
    if (!process.env.APNS_KEY_ID) {
      errors.push('APNS_KEY_ID is required when APNs is configured');
    }
    if (!process.env.APNS_TEAM_ID) {
      errors.push('APNS_TEAM_ID is required when APNs is configured');
    }
    if (!process.env.APNS_KEY_PATH) {
      errors.push('APNS_KEY_PATH is required when APNs is configured');
    }
  }
  
  // FCM validation
  const hasFcmConfig = process.env.FCM_PROJECT_ID || process.env.FCM_PRIVATE_KEY || process.env.FCM_CLIENT_EMAIL;
  if (hasFcmConfig) {
    if (!process.env.FCM_PROJECT_ID) {
      errors.push('FCM_PROJECT_ID is required when FCM is configured');
    }
    if (!process.env.FCM_PRIVATE_KEY) {
      errors.push('FCM_PRIVATE_KEY is required when FCM is configured');
    }
    if (!process.env.FCM_CLIENT_EMAIL) {
      errors.push('FCM_CLIENT_EMAIL is required when FCM is configured');
    }
  }
  
  return {
    isValid: errors.length === 0,
    errors,
    hasApns: hasApnsConfig && errors.filter(e => e.includes('APNS')).length === 0,
    hasFcm: hasFcmConfig && errors.filter(e => e.includes('FCM')).length === 0
  };
}

module.exports = {
  validateNotificationPayload,
  validateDevicePayload,
  sanitizeNotificationPayload,
  validatePushConfig
};