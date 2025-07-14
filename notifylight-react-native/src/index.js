// NotifyLight React Native SDK

import { NativeModules, NativeEventEmitter, AppState, Platform } from 'react-native';
import { 
  NOTIFICATION_TYPES, 
  MESSAGE_TYPES,
  APP_STATES, 
  DEFAULT_CONFIG, 
  EVENTS, 
  ERROR_CODES 
} from './constants';
import { 
  validateConfig, 
  getCurrentPlatform, 
  log, 
  createError, 
  registerDevice, 
  formatNotificationData,
  fetchInAppMessages,
  markMessageAsRead,
  formatInAppMessage,
  debounce 
} from './utils';
import InAppModal from './components/InAppModal';

class NotifyLight {
  constructor() {
    this.config = null;
    this.isInitialized = false;
    this.currentToken = null;
    this.eventHandlers = new Map();
    this.messageHandlers = new Map();
    this.nativeModule = null;
    this.eventEmitter = null;
    this.appStateSubscription = null;
    this.currentAppState = AppState.currentState;
    
    // In-app message state
    this.currentMessage = null;
    this.messageQueue = [];
    this.isShowingMessage = false;
    this.autoCheckInterval = null;
    this.modalComponent = null;
    
    // Debounced registration to prevent multiple rapid calls
    this.debouncedRegisterDevice = debounce(this._registerDeviceWithServer.bind(this), 1000);
  }

  /**
   * Initialize NotifyLight SDK
   */
  async initialize(userConfig) {
    try {
      // Merge user config with defaults
      this.config = { ...DEFAULT_CONFIG, ...userConfig };
      
      // Validate configuration
      validateConfig(this.config);
      
      log('Initializing NotifyLight SDK...', 'info', this.config.enableLogs);
      
      // Get native module
      this.nativeModule = this._getNativeModule();
      if (!this.nativeModule) {
        throw createError(
          ERROR_CODES.PLATFORM_NOT_SUPPORTED,
          'NotifyLight native module not found. Make sure you have linked the library correctly.'
        );
      }
      
      // Setup event emitter
      this.eventEmitter = new NativeEventEmitter(this.nativeModule);
      
      // Setup native event listeners
      this._setupNativeEventListeners();
      
      // Setup app state listener
      this._setupAppStateListener();
      
      // Auto-register if enabled
      if (this.config.autoRegister) {
        await this._initializeNotifications();
      }
      
      this.isInitialized = true;
      log('NotifyLight SDK initialized successfully', 'info', this.config.enableLogs);
      
      return { success: true };
    } catch (error) {
      log(`Initialization failed: ${error.message}`, 'error', this.config.enableLogs);
      throw error;
    }
  }

  /**
   * Register notification event handler
   */
  onNotification(handler) {
    if (typeof handler !== 'function') {
      throw new Error('Handler must be a function');
    }
    
    const handlerId = Date.now().toString();
    this.eventHandlers.set(handlerId, handler);
    
    return () => {
      this.eventHandlers.delete(handlerId);
    };
  }

  /**
   * Get current device token
   */
  async getToken() {
    if (!this.isInitialized) {
      throw createError(ERROR_CODES.INVALID_CONFIG, 'SDK not initialized');
    }
    
    try {
      if (this.currentToken) {
        return this.currentToken;
      }
      
      // Request token from native module
      const token = await this.nativeModule.getToken();
      this.currentToken = token;
      return token;
    } catch (error) {
      log(`Failed to get token: ${error.message}`, 'error', this.config.enableLogs);
      throw createError(ERROR_CODES.REGISTRATION_FAILED, error.message, error);
    }
  }

  /**
   * Request notification permissions (iOS specific)
   */
  async requestPermissions() {
    if (!this.isInitialized) {
      throw createError(ERROR_CODES.INVALID_CONFIG, 'SDK not initialized');
    }
    
    if (Platform.OS !== 'ios') {
      return { granted: true };
    }
    
    try {
      const result = await this.nativeModule.requestPermissions();
      log(`Permission request result: ${JSON.stringify(result)}`, 'info', this.config.enableLogs);
      return result;
    } catch (error) {
      log(`Permission request failed: ${error.message}`, 'error', this.config.enableLogs);
      throw createError(ERROR_CODES.PERMISSIONS_DENIED, error.message, error);
    }
  }

  /**
   * Manually register device (if auto-register is disabled)
   */
  async register() {
    if (!this.isInitialized) {
      throw createError(ERROR_CODES.INVALID_CONFIG, 'SDK not initialized');
    }
    
    return this._initializeNotifications();
  }

  /**
   * Register message event handler
   */
  onMessageDisplayed(handler) {
    if (typeof handler !== 'function') {
      throw new Error('Handler must be a function');
    }
    
    const handlerId = Date.now().toString();
    this.messageHandlers.set(handlerId, handler);
    
    return () => {
      this.messageHandlers.delete(handlerId);
    };
  }

  /**
   * Check for in-app messages manually
   */
  async checkForMessages() {
    if (!this.isInitialized) {
      throw createError(ERROR_CODES.INVALID_CONFIG, 'SDK not initialized');
    }
    
    if (!this.config.userId) {
      log('No userId configured, skipping message check', 'warn', this.config.enableLogs);
      return { messages: [] };
    }
    
    try {
      log('Checking for in-app messages...', 'info', this.config.enableLogs);
      
      const response = await fetchInAppMessages(
        this.config.apiUrl,
        this.config.apiKey,
        this.config.userId
      );
      
      const messages = response.messages || [];
      log(`Found ${messages.length} messages`, 'info', this.config.enableLogs);
      
      // Format messages and add to queue
      const formattedMessages = messages.map(formatInAppMessage);
      this._addMessagesToQueue(formattedMessages);
      
      // Show first message if not already showing one
      if (!this.isShowingMessage && this.messageQueue.length > 0) {
        this._showNextMessage();
      }
      
      this._notifyMessageHandlers(MESSAGE_TYPES.FETCH_SUCCESS, { 
        messages: formattedMessages,
        count: formattedMessages.length 
      });
      
      return { messages: formattedMessages };
      
    } catch (error) {
      log(`Failed to fetch messages: ${error.message}`, 'error', this.config.enableLogs);
      
      this._notifyMessageHandlers(MESSAGE_TYPES.FETCH_ERROR, { 
        error: error.message 
      });
      
      throw error;
    }
  }

  /**
   * Enable automatic message checking
   */
  enableAutoCheck(intervalMs = 30000) {
    if (!this.isInitialized) {
      throw createError(ERROR_CODES.INVALID_CONFIG, 'SDK not initialized');
    }
    
    this.disableAutoCheck(); // Clear existing interval
    
    log(`Enabling auto-check every ${intervalMs}ms`, 'info', this.config.enableLogs);
    
    this.autoCheckInterval = setInterval(() => {
      this.checkForMessages().catch(error => {
        log(`Auto-check failed: ${error.message}`, 'error', this.config.enableLogs);
      });
    }, intervalMs);
    
    // Immediate check
    this.checkForMessages().catch(error => {
      log(`Initial message check failed: ${error.message}`, 'error', this.config.enableLogs);
    });
  }

  /**
   * Disable automatic message checking
   */
  disableAutoCheck() {
    if (this.autoCheckInterval) {
      clearInterval(this.autoCheckInterval);
      this.autoCheckInterval = null;
      log('Auto-check disabled', 'info', this.config.enableLogs);
    }
  }

  /**
   * Show a custom in-app message
   */
  showMessage(message, options = {}) {
    const formattedMessage = {
      id: message.id || Date.now().toString(),
      title: message.title || '',
      message: message.message || '',
      actions: message.actions || [],
      data: message.data || {},
      ...message
    };
    
    this._showMessage(formattedMessage, options);
  }

  /**
   * Get the modal component for rendering
   */
  getModalComponent() {
    return InAppModal;
  }

  /**
   * Cleanup and remove listeners
   */
  cleanup() {
    log('Cleaning up NotifyLight SDK', 'info', this.config.enableLogs);
    
    // Disable auto-check
    this.disableAutoCheck();
    
    // Clear message queue
    this.messageQueue = [];
    this.currentMessage = null;
    this.isShowingMessage = false;
    
    // Remove native event listeners
    if (this.eventEmitter) {
      this.eventEmitter.removeAllListeners(EVENTS.NATIVE_TOKEN_RECEIVED);
      this.eventEmitter.removeAllListeners(EVENTS.NATIVE_TOKEN_REFRESH);
      this.eventEmitter.removeAllListeners(EVENTS.NATIVE_NOTIFICATION_RECEIVED);
      this.eventEmitter.removeAllListeners(EVENTS.NATIVE_NOTIFICATION_OPENED);
      this.eventEmitter.removeAllListeners(EVENTS.NATIVE_REGISTRATION_ERROR);
    }
    
    // Remove app state listener
    if (this.appStateSubscription) {
      this.appStateSubscription.remove();
    }
    
    // Clear handlers
    this.eventHandlers.clear();
    this.messageHandlers.clear();
    
    this.isInitialized = false;
  }

  // Private methods

  _getNativeModule() {
    const { NotifyLightModule } = NativeModules;
    return NotifyLightModule;
  }

  _setupNativeEventListeners() {
    // Token received
    this.eventEmitter.addListener(EVENTS.NATIVE_TOKEN_RECEIVED, (token) => {
      log(`Token received: ${token.substring(0, 20)}...`, 'info', this.config.enableLogs);
      this.currentToken = token;
      this.debouncedRegisterDevice(token);
      this._notifyHandlers(NOTIFICATION_TYPES.TOKEN_RECEIVED, { token });
    });

    // Token refresh
    this.eventEmitter.addListener(EVENTS.NATIVE_TOKEN_REFRESH, (token) => {
      log(`Token refreshed: ${token.substring(0, 20)}...`, 'info', this.config.enableLogs);
      this.currentToken = token;
      this.debouncedRegisterDevice(token);
      this._notifyHandlers(NOTIFICATION_TYPES.TOKEN_REFRESH, { token });
    });

    // Notification received (app in foreground)
    this.eventEmitter.addListener(EVENTS.NATIVE_NOTIFICATION_RECEIVED, (notification) => {
      log('Notification received in foreground', 'info', this.config.enableLogs);
      const formattedData = formatNotificationData(notification, APP_STATES.FOREGROUND);
      this._notifyHandlers(NOTIFICATION_TYPES.RECEIVED, formattedData);
    });

    // Notification opened (app opened from notification)
    this.eventEmitter.addListener(EVENTS.NATIVE_NOTIFICATION_OPENED, (notification) => {
      log('Notification opened', 'info', this.config.enableLogs);
      const appState = this.currentAppState === 'active' ? APP_STATES.FOREGROUND : APP_STATES.BACKGROUND;
      const formattedData = formatNotificationData(notification, appState);
      this._notifyHandlers(NOTIFICATION_TYPES.OPENED, formattedData);
    });

    // Registration error
    this.eventEmitter.addListener(EVENTS.NATIVE_REGISTRATION_ERROR, (error) => {
      log(`Registration error: ${error.message}`, 'error', this.config.enableLogs);
      this._notifyHandlers(NOTIFICATION_TYPES.REGISTRATION_ERROR, error);
    });
  }

  _setupAppStateListener() {
    this.appStateSubscription = AppState.addEventListener('change', (nextAppState) => {
      log(`App state changed: ${this.currentAppState} -> ${nextAppState}`, 'debug', this.config.enableLogs);
      this.currentAppState = nextAppState;
    });
  }

  async _initializeNotifications() {
    try {
      // Request permissions on iOS
      if (this.config.requestPermissions && Platform.OS === 'ios') {
        const permissions = await this.requestPermissions();
        if (!permissions.granted) {
          throw createError(ERROR_CODES.PERMISSIONS_DENIED, 'Notification permissions denied');
        }
      }

      // Initialize native module
      await this.nativeModule.initialize({
        showNotificationsWhenInForeground: this.config.showNotificationsWhenInForeground
      });

      log('Native module initialized', 'info', this.config.enableLogs);
    } catch (error) {
      log(`Failed to initialize notifications: ${error.message}`, 'error', this.config.enableLogs);
      throw error;
    }
  }

  async _registerDeviceWithServer(token) {
    if (!token || !this.config) return;
    
    try {
      log('Registering device with server...', 'info', this.config.enableLogs);
      
      const result = await registerDevice(
        this.config.apiUrl,
        this.config.apiKey,
        token,
        getCurrentPlatform(),
        this.config.userId
      );
      
      log('Device registered successfully', 'info', this.config.enableLogs);
      return result;
    } catch (error) {
      log(`Device registration failed: ${error.message}`, 'error', this.config.enableLogs);
      // Don't throw here - registration can be retried
    }
  }

  _notifyHandlers(type, data) {
    this.eventHandlers.forEach((handler) => {
      try {
        handler(type, data);
      } catch (error) {
        log(`Handler error: ${error.message}`, 'error', this.config.enableLogs);
      }
    });
  }

  _notifyMessageHandlers(type, data) {
    this.messageHandlers.forEach((handler) => {
      try {
        handler(type, data);
      } catch (error) {
        log(`Message handler error: ${error.message}`, 'error', this.config.enableLogs);
      }
    });
  }

  _addMessagesToQueue(messages) {
    // Add new messages to queue, avoiding duplicates
    messages.forEach(message => {
      const exists = this.messageQueue.find(m => m.id === message.id);
      if (!exists) {
        this.messageQueue.push(message);
      }
    });
  }

  _showNextMessage() {
    if (this.isShowingMessage || this.messageQueue.length === 0) {
      return;
    }

    const message = this.messageQueue.shift();
    this._showMessage(message);
  }

  _showMessage(message, options = {}) {
    if (this.isShowingMessage) {
      // Add to queue if already showing a message
      this.messageQueue.unshift(message);
      return;
    }

    this.isShowingMessage = true;
    this.currentMessage = message;

    log(`Showing message: ${message.title}`, 'info', this.config.enableLogs);

    // Mark message as read when displayed
    if (message.id && this.config.apiUrl && this.config.apiKey) {
      this._markMessageAsRead(message.id).catch(error => {
        log(`Failed to mark message as read: ${error.message}`, 'warn', this.config.enableLogs);
      });
    }

    // Notify handlers
    this._notifyMessageHandlers(MESSAGE_TYPES.DISPLAYED, {
      message,
      displayedAt: Date.now(),
      queueLength: this.messageQueue.length
    });
  }

  _hideMessage() {
    if (!this.isShowingMessage) {
      return;
    }

    const message = this.currentMessage;
    
    this.isShowingMessage = false;
    this.currentMessage = null;

    log(`Message dismissed: ${message ? message.title : 'unknown'}`, 'info', this.config.enableLogs);

    // Notify handlers
    this._notifyMessageHandlers(MESSAGE_TYPES.DISMISSED, {
      message,
      dismissedAt: Date.now(),
      queueLength: this.messageQueue.length
    });

    // Show next message if available
    if (this.messageQueue.length > 0) {
      setTimeout(() => {
        this._showNextMessage();
      }, 500); // Small delay between messages
    }
  }

  _handleMessageAction(action, message) {
    log(`Message action: ${action.title}`, 'info', this.config.enableLogs);

    // Notify handlers
    this._notifyMessageHandlers(MESSAGE_TYPES.ACTION_PRESSED, {
      action,
      message,
      actionAt: Date.now()
    });

    // Hide message unless action prevents it
    if (!action.preventDismiss) {
      this._hideMessage();
    }
  }

  async _markMessageAsRead(messageId) {
    try {
      await markMessageAsRead(
        this.config.apiUrl,
        this.config.apiKey,
        messageId
      );
      log(`Message marked as read: ${messageId}`, 'info', this.config.enableLogs);
    } catch (error) {
      log(`Failed to mark message as read: ${error.message}`, 'error', this.config.enableLogs);
      throw error;
    }
  }
}

// Export singleton instance
const notifyLight = new NotifyLight();

export default notifyLight;

// Named exports for convenience
export {
  NOTIFICATION_TYPES,
  MESSAGE_TYPES,
  APP_STATES,
  ERROR_CODES
} from './constants';

export { notifyLight as NotifyLight };
export { default as InAppModal } from './components/InAppModal';