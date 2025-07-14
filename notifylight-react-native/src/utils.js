// NotifyLight React Native SDK Utilities

import { Platform } from 'react-native';
import { PLATFORMS, ERROR_CODES } from './constants';

/**
 * Validates the configuration object
 */
export function validateConfig(config) {
  if (!config || typeof config !== 'object') {
    throw new Error('Configuration must be an object');
  }

  if (!config.apiUrl || typeof config.apiUrl !== 'string') {
    throw new Error('apiUrl is required and must be a string');
  }

  if (!config.apiKey || typeof config.apiKey !== 'string') {
    throw new Error('apiKey is required and must be a string');
  }

  if (config.userId && typeof config.userId !== 'string') {
    throw new Error('userId must be a string');
  }

  // Validate URL format
  try {
    new URL(config.apiUrl);
  } catch (error) {
    throw new Error('apiUrl must be a valid URL');
  }

  return true;
}

/**
 * Gets the current platform
 */
export function getCurrentPlatform() {
  return Platform.OS === 'ios' ? PLATFORMS.IOS : PLATFORMS.ANDROID;
}

/**
 * Logs messages if logging is enabled
 */
export function log(message, level = 'info', enableLogs = true) {
  if (!enableLogs) return;
  
  const timestamp = new Date().toISOString();
  const prefix = `[NotifyLight ${timestamp}]`;
  
  switch (level) {
    case 'error':
      console.error(prefix, message);
      break;
    case 'warn':
      console.warn(prefix, message);
      break;
    case 'debug':
      console.debug(prefix, message);
      break;
    default:
      console.log(prefix, message);
  }
}

/**
 * Creates a standardized error object
 */
export function createError(code, message, originalError = null) {
  const error = new Error(message);
  error.code = code;
  error.originalError = originalError;
  return error;
}

/**
 * Makes HTTP requests to the NotifyLight API
 */
export async function makeApiRequest(url, options = {}) {
  const defaultOptions = {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json'
    }
  };

  const requestOptions = {
    ...defaultOptions,
    ...options,
    headers: {
      ...defaultOptions.headers,
      ...options.headers
    }
  };

  try {
    const response = await fetch(url, requestOptions);
    
    if (!response.ok) {
      const errorText = await response.text();
      throw createError(
        ERROR_CODES.NETWORK_ERROR,
        `HTTP ${response.status}: ${errorText}`,
        new Error(`Network request failed with status ${response.status}`)
      );
    }

    const responseText = await response.text();
    
    try {
      return JSON.parse(responseText);
    } catch (parseError) {
      return responseText;
    }
  } catch (error) {
    if (error.code) {
      throw error;
    }
    
    throw createError(
      ERROR_CODES.NETWORK_ERROR,
      `Network request failed: ${error.message}`,
      error
    );
  }
}

/**
 * Registers device with NotifyLight server
 */
export async function registerDevice(apiUrl, apiKey, token, platform, userId) {
  const url = `${apiUrl}/register-device`;
  
  const payload = {
    token,
    platform,
    userId: userId || 'anonymous'
  };

  const options = {
    method: 'POST',
    headers: {
      'X-API-Key': apiKey
    },
    body: JSON.stringify(payload)
  };

  return makeApiRequest(url, options);
}

/**
 * Formats notification data for consistent handling
 */
export function formatNotificationData(rawData, appState = 'unknown') {
  const data = rawData || {};
  
  return {
    id: data.id || data.messageId || data.google?.messageId || Date.now().toString(),
    title: data.title || data.notification?.title || '',
    message: data.message || data.body || data.notification?.body || '',
    data: data.data || data.customData || {},
    appState,
    receivedAt: Date.now(),
    platform: getCurrentPlatform(),
    raw: data
  };
}

/**
 * Debounces function calls
 */
export function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

/**
 * Fetches in-app messages for a user
 */
export async function fetchInAppMessages(apiUrl, apiKey, userId) {
  const url = `${apiUrl}/messages/${encodeURIComponent(userId)}`;
  
  const options = {
    method: 'GET',
    headers: {
      'X-API-Key': apiKey
    }
  };

  return makeApiRequest(url, options);
}

/**
 * Marks an in-app message as read
 */
export async function markMessageAsRead(apiUrl, apiKey, messageId) {
  const url = `${apiUrl}/messages/${encodeURIComponent(messageId)}/read`;
  
  const options = {
    method: 'POST',
    headers: {
      'X-API-Key': apiKey
    }
  };

  return makeApiRequest(url, options);
}

/**
 * Formats in-app message for display
 */
export function formatInAppMessage(rawMessage) {
  return {
    id: rawMessage.id,
    title: rawMessage.title || '',
    message: rawMessage.message || '',
    createdAt: rawMessage.createdAt,
    status: rawMessage.status,
    actions: rawMessage.actions || [],
    data: rawMessage.data || {},
    raw: rawMessage
  };
}