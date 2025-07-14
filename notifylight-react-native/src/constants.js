// NotifyLight React Native SDK Constants

export const NOTIFICATION_TYPES = {
  RECEIVED: 'notificationReceived',
  OPENED: 'notificationOpened',
  TOKEN_RECEIVED: 'tokenReceived',
  TOKEN_REFRESH: 'tokenRefresh',
  REGISTRATION_ERROR: 'registrationError'
};

export const MESSAGE_TYPES = {
  DISPLAYED: 'messageDisplayed',
  DISMISSED: 'messageDismissed',
  ACTION_PRESSED: 'messageActionPressed',
  FETCH_SUCCESS: 'messageFetchSuccess',
  FETCH_ERROR: 'messageFetchError'
};

export const APP_STATES = {
  FOREGROUND: 'foreground',
  BACKGROUND: 'background',
  QUIT: 'quit'
};

export const PLATFORMS = {
  IOS: 'ios',
  ANDROID: 'android'
};

export const DEFAULT_CONFIG = {
  autoRegister: true,
  requestPermissions: true,
  showNotificationsWhenInForeground: false,
  enableLogs: __DEV__
};

export const EVENTS = {
  // Native module events
  NATIVE_TOKEN_RECEIVED: 'NotifyLightTokenReceived',
  NATIVE_TOKEN_REFRESH: 'NotifyLightTokenRefresh',
  NATIVE_NOTIFICATION_RECEIVED: 'NotifyLightNotificationReceived',
  NATIVE_NOTIFICATION_OPENED: 'NotifyLightNotificationOpened',
  NATIVE_REGISTRATION_ERROR: 'NotifyLightRegistrationError'
};

export const ERROR_CODES = {
  PERMISSIONS_DENIED: 'PERMISSIONS_DENIED',
  REGISTRATION_FAILED: 'REGISTRATION_FAILED',
  NETWORK_ERROR: 'NETWORK_ERROR',
  INVALID_CONFIG: 'INVALID_CONFIG',
  PLATFORM_NOT_SUPPORTED: 'PLATFORM_NOT_SUPPORTED'
};