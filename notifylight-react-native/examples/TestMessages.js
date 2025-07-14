// Test Message Payloads and Styling Examples for NotifyLight SDK

import NotifyLight from 'notifylight-react-native';

// Test message payloads for server-side creation
export const TEST_MESSAGE_PAYLOADS = {
  // Basic message
  basicMessage: {
    type: "in-app",
    title: "Welcome to NotifyLight",
    message: "This is a basic in-app message without any actions.",
    users: ["demo-user-123"]
  },

  // Message with actions
  messageWithActions: {
    type: "in-app",
    title: "Update Available",
    message: "A new version of the app is available. Would you like to update now?",
    users: ["demo-user-123"],
    actions: [
      {
        id: "update",
        title: "Update Now",
        style: "primary"
      },
      {
        id: "later",
        title: "Later",
        style: "secondary"
      }
    ]
  },

  // Promotional message
  promoMessage: {
    type: "in-app",
    title: "Special Offer!",
    message: "Get 50% off your next purchase. Limited time offer ends soon!",
    users: ["demo-user-123"],
    actions: [
      {
        id: "claim",
        title: "Claim Offer",
        style: "primary"
      },
      {
        id: "dismiss",
        title: "No Thanks",
        style: "secondary"
      }
    ],
    data: {
      screen: "OffersScreen",
      offerCode: "SAVE50"
    }
  },

  // Survey message
  surveyMessage: {
    type: "in-app",
    title: "Quick Survey",
    message: "How would you rate your experience with our app?",
    users: ["demo-user-123"],
    actions: [
      {
        id: "excellent",
        title: "Excellent",
        style: "primary"
      },
      {
        id: "good",
        title: "Good",
        style: "secondary"
      },
      {
        id: "poor",
        title: "Poor",
        style: "secondary"
      }
    ]
  },

  // Information message
  infoMessage: {
    type: "in-app",
    title: "Maintenance Notice",
    message: "The app will be under maintenance from 2 AM to 4 AM tonight. Some features may be unavailable during this time.",
    users: ["all"],
    actions: [
      {
        id: "understood",
        title: "Understood",
        style: "primary"
      }
    ]
  }
};

// Curl commands for testing (to be executed from terminal)
export const CURL_COMMANDS = {
  basicMessage: `curl -X POST https://your-notifylight-server.com/notify \\
  -H "Content-Type: application/json" \\
  -H "X-API-Key: your-api-key" \\
  -d '${JSON.stringify(TEST_MESSAGE_PAYLOADS.basicMessage)}'`,

  messageWithActions: `curl -X POST https://your-notifylight-server.com/notify \\
  -H "Content-Type: application/json" \\
  -H "X-API-Key: your-api-key" \\
  -d '${JSON.stringify(TEST_MESSAGE_PAYLOADS.messageWithActions)}'`,

  promoMessage: `curl -X POST https://your-notifylight-server.com/notify \\
  -H "Content-Type: application/json" \\
  -H "X-API-Key: your-api-key" \\
  -d '${JSON.stringify(TEST_MESSAGE_PAYLOADS.promoMessage)}'`,
};

// Custom styling examples
export const MODAL_STYLES = {
  // Modern style with rounded corners and shadows
  modern: {
    modal: {
      backgroundColor: '#FFFFFF',
      borderRadius: 20,
      marginHorizontal: 20,
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 20 },
      shadowOpacity: 0.3,
      shadowRadius: 30,
      elevation: 20,
    },
    title: {
      fontSize: 22,
      fontWeight: '700',
      color: '#1A202C',
      textAlign: 'center',
    },
    message: {
      fontSize: 16,
      lineHeight: 24,
      color: '#4A5568',
      textAlign: 'center',
    },
    primaryButton: {
      backgroundColor: '#667EEA',
      borderRadius: 12,
      paddingVertical: 16,
    },
    primaryButtonText: {
      fontSize: 16,
      fontWeight: '600',
    },
    secondaryButton: {
      backgroundColor: '#F7FAFC',
      borderRadius: 12,
      paddingVertical: 16,
      borderWidth: 1,
      borderColor: '#E2E8F0',
    },
    secondaryButtonText: {
      color: '#4A5568',
      fontSize: 16,
      fontWeight: '500',
    },
  },

  // Dark theme
  dark: {
    modal: {
      backgroundColor: '#2D3748',
      borderRadius: 16,
      marginHorizontal: 20,
    },
    title: {
      fontSize: 20,
      fontWeight: '600',
      color: '#F7FAFC',
      textAlign: 'center',
    },
    message: {
      fontSize: 16,
      lineHeight: 24,
      color: '#CBD5E0',
      textAlign: 'center',
    },
    primaryButton: {
      backgroundColor: '#4299E1',
      borderRadius: 8,
    },
    primaryButtonText: {
      color: '#FFFFFF',
      fontSize: 16,
      fontWeight: '600',
    },
    secondaryButton: {
      backgroundColor: '#4A5568',
      borderRadius: 8,
    },
    secondaryButtonText: {
      color: '#E2E8F0',
      fontSize: 16,
      fontWeight: '500',
    },
  },

  // Minimal style
  minimal: {
    modal: {
      backgroundColor: '#FFFFFF',
      borderRadius: 8,
      marginHorizontal: 24,
    },
    title: {
      fontSize: 18,
      fontWeight: '500',
      color: '#000000',
      textAlign: 'left',
    },
    message: {
      fontSize: 16,
      lineHeight: 22,
      color: '#666666',
      textAlign: 'left',
    },
    primaryButton: {
      backgroundColor: '#000000',
      borderRadius: 4,
      paddingVertical: 14,
    },
    primaryButtonText: {
      color: '#FFFFFF',
      fontSize: 14,
      fontWeight: '500',
    },
    secondaryButton: {
      backgroundColor: 'transparent',
      borderRadius: 4,
      paddingVertical: 14,
      borderWidth: 1,
      borderColor: '#000000',
    },
    secondaryButtonText: {
      color: '#000000',
      fontSize: 14,
      fontWeight: '500',
    },
  },

  // Colorful/Brand style
  brand: {
    modal: {
      backgroundColor: '#FFFFFF',
      borderRadius: 16,
      marginHorizontal: 16,
      borderTopWidth: 4,
      borderTopColor: '#FF6B6B',
    },
    title: {
      fontSize: 20,
      fontWeight: '700',
      color: '#2C3E50',
      textAlign: 'center',
    },
    message: {
      fontSize: 16,
      lineHeight: 24,
      color: '#34495E',
      textAlign: 'center',
    },
    primaryButton: {
      backgroundColor: '#FF6B6B',
      borderRadius: 25,
      paddingVertical: 14,
    },
    primaryButtonText: {
      color: '#FFFFFF',
      fontSize: 16,
      fontWeight: '600',
    },
    secondaryButton: {
      backgroundColor: 'transparent',
      borderRadius: 25,
      paddingVertical: 14,
      borderWidth: 2,
      borderColor: '#FF6B6B',
    },
    secondaryButtonText: {
      color: '#FF6B6B',
      fontSize: 16,
      fontWeight: '600',
    },
  },

  // iOS-like style
  ios: {
    modal: {
      backgroundColor: '#FFFFFF',
      borderRadius: 14,
      marginHorizontal: 40,
    },
    title: {
      fontSize: 17,
      fontWeight: '600',
      color: '#000000',
      textAlign: 'center',
    },
    message: {
      fontSize: 13,
      lineHeight: 18,
      color: '#000000',
      textAlign: 'center',
    },
    actions: {
      paddingHorizontal: 0,
      paddingBottom: 0,
      gap: 0,
    },
    primaryButton: {
      backgroundColor: 'transparent',
      borderRadius: 0,
      paddingVertical: 14,
      borderTopWidth: 0.5,
      borderTopColor: '#C6C6C8',
    },
    primaryButtonText: {
      color: '#007AFF',
      fontSize: 17,
      fontWeight: '400',
    },
    secondaryButton: {
      backgroundColor: 'transparent',
      borderRadius: 0,
      paddingVertical: 14,
      borderTopWidth: 0.5,
      borderTopColor: '#C6C6C8',
    },
    secondaryButtonText: {
      color: '#007AFF',
      fontSize: 17,
      fontWeight: '400',
    },
  },
};

// Example usage functions
export const showTestMessage = (style = 'modern') => {
  const message = {
    id: 'test-' + Date.now(),
    title: 'Test Message',
    message: 'This is a test message with custom styling applied.',
    actions: [
      {
        id: 'primary',
        title: 'Primary Action',
        style: 'primary',
      },
      {
        id: 'secondary',
        title: 'Secondary Action',
        style: 'secondary',
      },
    ],
  };

  NotifyLight.showMessage(message, { style: MODAL_STYLES[style] });
};

export const showCustomMessage = (config) => {
  const message = {
    id: config.id || 'custom-' + Date.now(),
    title: config.title || 'Custom Message',
    message: config.message || 'This is a custom message.',
    actions: config.actions || [
      {
        id: 'ok',
        title: 'OK',
        style: 'primary',
      },
    ],
    data: config.data || {},
  };

  NotifyLight.showMessage(message, config.options || {});
};

// Animation examples
export const ANIMATION_EXAMPLES = {
  slide: {
    animationType: 'slide',
    enableSwipeToDismiss: true,
    enableBackdropDismiss: true,
  },
  fade: {
    animationType: 'fade',
    enableSwipeToDismiss: false,
    enableBackdropDismiss: true,
  },
  scale: {
    animationType: 'scale',
    enableSwipeToDismiss: false,
    enableBackdropDismiss: true,
  },
};

// Testing helper functions
export const TestingHelpers = {
  // Show multiple messages in sequence
  showSequence: (messages, delay = 2000) => {
    messages.forEach((message, index) => {
      setTimeout(() => {
        NotifyLight.showMessage(message);
      }, index * delay);
    });
  },

  // Show message with custom actions that log to console
  showWithLogging: (message) => {
    const messageWithLogging = {
      ...message,
      actions: message.actions?.map(action => ({
        ...action,
        onPress: () => {
          console.log(`Action pressed: ${action.title}`, action);
        },
      })),
    };

    NotifyLight.showMessage(messageWithLogging);
  },

  // Test auto-dismiss message
  showAutoDismiss: (message, delay = 3000) => {
    NotifyLight.showMessage(message);
    setTimeout(() => {
      // Force dismiss by showing empty message queue
      console.log('Auto-dismissing message');
    }, delay);
  },
};