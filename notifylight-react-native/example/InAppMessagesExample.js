// Example React Native App with In-App Messages using NotifyLight SDK

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Alert,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
  Switch,
} from 'react-native';

import NotifyLight, { 
  NOTIFICATION_TYPES, 
  MESSAGE_TYPES,
  APP_STATES, 
  ERROR_CODES,
  InAppModal
} from 'notifylight-react-native';

export default function InAppMessagesExample() {
  const [isInitialized, setIsInitialized] = useState(false);
  const [token, setToken] = useState(null);
  const [notifications, setNotifications] = useState([]);
  const [messages, setMessages] = useState([]);
  const [status, setStatus] = useState('Initializing...');
  const [autoCheckEnabled, setAutoCheckEnabled] = useState(false);
  const [currentMessage, setCurrentMessage] = useState(null);
  const [showModal, setShowModal] = useState(false);

  useEffect(() => {
    initializeNotifyLight();
    
    return () => {
      // Cleanup when component unmounts
      NotifyLight.cleanup();
    };
  }, []);

  const initializeNotifyLight = async () => {
    try {
      setStatus('Initializing NotifyLight...');
      
      // Initialize with your NotifyLight server configuration
      await NotifyLight.initialize({
        apiUrl: 'https://your-notifylight-server.com', // Replace with your server URL
        apiKey: 'your-api-key-here', // Replace with your API key
        userId: 'demo-user-123', // Replace with actual user ID
        autoRegister: true,
        requestPermissions: true,
        showNotificationsWhenInForeground: false,
        enableLogs: true, // Enable for development
      });

      setIsInitialized(true);
      setStatus('NotifyLight initialized successfully');

      // Set up notification listener
      const unsubscribeNotifications = NotifyLight.onNotification((type, data) => {
        console.log('Notification event:', type, data);
        
        switch (type) {
          case NOTIFICATION_TYPES.RECEIVED:
            handleNotificationReceived(data);
            break;
            
          case NOTIFICATION_TYPES.OPENED:
            handleNotificationOpened(data);
            break;
            
          case NOTIFICATION_TYPES.TOKEN_RECEIVED:
          case NOTIFICATION_TYPES.TOKEN_REFRESH:
            handleTokenUpdate(data.token);
            break;
            
          case NOTIFICATION_TYPES.REGISTRATION_ERROR:
            handleRegistrationError(data);
            break;
        }
      });

      // Set up message listener
      const unsubscribeMessages = NotifyLight.onMessageDisplayed((type, data) => {
        console.log('Message event:', type, data);
        
        switch (type) {
          case MESSAGE_TYPES.DISPLAYED:
            handleMessageDisplayed(data);
            break;
            
          case MESSAGE_TYPES.DISMISSED:
            handleMessageDismissed(data);
            break;
            
          case MESSAGE_TYPES.ACTION_PRESSED:
            handleMessageActionPressed(data);
            break;
            
          case MESSAGE_TYPES.FETCH_SUCCESS:
            handleMessagesFetched(data);
            break;
            
          case MESSAGE_TYPES.FETCH_ERROR:
            handleMessagesFetchError(data);
            break;
        }
      });

      // Get initial token
      try {
        const initialToken = await NotifyLight.getToken();
        setToken(initialToken);
      } catch (error) {
        console.log('No initial token available');
      }

      // Check for messages immediately
      checkForMessages();

    } catch (error) {
      console.error('NotifyLight initialization failed:', error);
      setStatus(`Initialization failed: ${error.message}`);
      
      // Handle specific error types
      if (error.code === ERROR_CODES.INVALID_CONFIG) {
        Alert.alert('Configuration Error', 'Please check your API URL and API key');
      } else if (error.code === ERROR_CODES.PERMISSIONS_DENIED) {
        Alert.alert('Permissions Required', 'Please enable notifications in device settings');
      }
    }
  };

  const handleNotificationReceived = (data) => {
    const notification = {
      id: data.id,
      title: data.title,
      message: data.message,
      type: 'received',
      timestamp: new Date().toLocaleTimeString(),
      appState: data.appState,
    };
    
    setNotifications(prev => [notification, ...prev.slice(0, 9)]);
  };

  const handleNotificationOpened = (data) => {
    const notification = {
      id: data.id,
      title: data.title,
      message: data.message,
      type: 'opened',
      timestamp: new Date().toLocaleTimeString(),
      appState: data.appState,
    };
    
    setNotifications(prev => [notification, ...prev.slice(0, 9)]);
  };

  const handleTokenUpdate = (newToken) => {
    setToken(newToken);
    setStatus('Device registered successfully');
  };

  const handleRegistrationError = (error) => {
    setStatus(`Registration failed: ${error.message}`);
  };

  const handleMessageDisplayed = (data) => {
    console.log('Message displayed:', data.message.title);
    setCurrentMessage(data.message);
    setShowModal(true);
  };

  const handleMessageDismissed = (data) => {
    console.log('Message dismissed:', data.message.title);
    setShowModal(false);
    setCurrentMessage(null);
  };

  const handleMessageActionPressed = (data) => {
    console.log('Message action pressed:', data.action.title);
    Alert.alert('Action Pressed', `Action: ${data.action.title}`);
  };

  const handleMessagesFetched = (data) => {
    console.log(`Fetched ${data.count} messages`);
    setMessages(data.messages);
    setStatus(`Found ${data.count} messages`);
  };

  const handleMessagesFetchError = (data) => {
    console.error('Failed to fetch messages:', data.error);
    setStatus(`Message fetch failed: ${data.error}`);
  };

  const checkForMessages = async () => {
    if (!isInitialized) return;
    
    try {
      setStatus('Checking for messages...');
      await NotifyLight.checkForMessages();
    } catch (error) {
      Alert.alert('Error', `Failed to check messages: ${error.message}`);
    }
  };

  const toggleAutoCheck = (enabled) => {
    setAutoCheckEnabled(enabled);
    
    if (enabled) {
      NotifyLight.enableAutoCheck(10000); // Check every 10 seconds for demo
      setStatus('Auto-check enabled (10s interval)');
    } else {
      NotifyLight.disableAutoCheck();
      setStatus('Auto-check disabled');
    }
  };

  const showCustomMessage = () => {
    const customMessage = {
      id: 'custom-' + Date.now(),
      title: 'Custom Message',
      message: 'This is a custom in-app message with actions!',
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
    
    NotifyLight.showMessage(customMessage);
  };

  const handleModalClose = () => {
    setShowModal(false);
    setCurrentMessage(null);
    // SDK will automatically handle the next message in queue
  };

  const handleModalAction = (action, message) => {
    console.log('Modal action:', action, message);
    Alert.alert('Action', `Pressed: ${action.title}`);
  };

  // Custom styling for the modal
  const customModalStyle = {
    modal: {
      backgroundColor: '#F8F9FA',
      borderRadius: 20,
      marginHorizontal: 16,
    },
    title: {
      fontSize: 20,
      fontWeight: '700',
      color: '#1A202C',
    },
    message: {
      fontSize: 16,
      lineHeight: 24,
      color: '#4A5568',
    },
    primaryButton: {
      backgroundColor: '#4299E1',
      borderRadius: 12,
    },
    secondaryButton: {
      backgroundColor: '#EDF2F7',
      borderRadius: 12,
    },
    secondaryButtonText: {
      color: '#4A5568',
    },
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <Text style={styles.title}>NotifyLight In-App Messages</Text>
        
        <View style={styles.statusContainer}>
          <Text style={styles.statusLabel}>Status:</Text>
          <Text style={[styles.statusText, { color: isInitialized ? 'green' : 'orange' }]}>
            {status}
          </Text>
        </View>

        <View style={styles.controlsContainer}>
          <TouchableOpacity style={styles.button} onPress={checkForMessages}>
            <Text style={styles.buttonText}>Check Messages</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.button} onPress={showCustomMessage}>
            <Text style={styles.buttonText}>Show Custom Message</Text>
          </TouchableOpacity>
          
          <View style={styles.switchContainer}>
            <Text style={styles.switchLabel}>Auto-check:</Text>
            <Switch
              value={autoCheckEnabled}
              onValueChange={toggleAutoCheck}
              disabled={!isInitialized}
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>In-App Messages ({messages.length})</Text>
          
          {messages.length === 0 ? (
            <Text style={styles.emptyText}>
              No messages available. Create some in-app messages from your server.
            </Text>
          ) : (
            messages.map((message, index) => (
              <View key={`${message.id}-${index}`} style={styles.messageItem}>
                <Text style={styles.messageTitle}>{message.title}</Text>
                <Text style={styles.messageText}>{message.message}</Text>
                <Text style={styles.messageDate}>
                  {new Date(message.createdAt).toLocaleString()}
                </Text>
              </View>
            ))
          )}
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Push Notifications ({notifications.length})</Text>
          
          {notifications.length === 0 ? (
            <Text style={styles.emptyText}>
              No push notifications yet.
            </Text>
          ) : (
            notifications.map((notification, index) => (
              <View key={`${notification.id}-${index}`} style={styles.notificationItem}>
                <Text style={styles.messageTitle}>{notification.title}</Text>
                <Text style={styles.messageText}>{notification.message}</Text>
                <View style={styles.notificationMeta}>
                  <Text style={styles.notificationBadge}>
                    {notification.type}
                  </Text>
                  <Text style={styles.messageDate}>
                    {notification.timestamp}
                  </Text>
                </View>
              </View>
            ))
          )}
        </View>

        <View style={styles.testInstructions}>
          <Text style={styles.sectionTitle}>Test Instructions</Text>
          <Text style={styles.instructionText}>
            1. Create in-app messages from your server:{'\n'}
          </Text>
          <Text style={styles.codeText}>
            curl -X POST https://your-server.com/notify \{'\n'}
            {'  '}-H "Content-Type: application/json" \{'\n'}
            {'  '}-H "X-API-Key: your-api-key" \{'\n'}
            {'  '}-d '{"{"}{"type": "in-app", "title": "Test Message", "message": "Hello from server!", "users": ["demo-user-123"]{"}"}'
          </Text>
        </View>
      </ScrollView>

      {/* In-App Modal */}
      <InAppModal
        visible={showModal}
        message={currentMessage}
        onClose={handleModalClose}
        onActionPress={handleModalAction}
        style={customModalStyle}
        enableSwipeToDismiss={true}
        enableBackdropDismiss={true}
        animationType="slide"
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  scrollView: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
    color: '#333',
  },
  statusContainer: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  statusLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#666',
    marginBottom: 4,
  },
  statusText: {
    fontSize: 16,
    fontWeight: '500',
  },
  controlsContainer: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  button: {
    backgroundColor: '#2196F3',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 6,
    marginBottom: 12,
    alignItems: 'center',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: '500',
  },
  switchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  switchLabel: {
    fontSize: 16,
    color: '#333',
  },
  section: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 12,
    color: '#333',
  },
  emptyText: {
    textAlign: 'center',
    color: '#666',
    fontStyle: 'italic',
    marginVertical: 20,
  },
  messageItem: {
    backgroundColor: '#f8f9fa',
    padding: 12,
    borderRadius: 6,
    marginBottom: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#4CAF50',
  },
  notificationItem: {
    backgroundColor: '#f8f9fa',
    padding: 12,
    borderRadius: 6,
    marginBottom: 8,
    borderLeftWidth: 3,
    borderLeftColor: '#2196F3',
  },
  messageTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 4,
  },
  messageText: {
    fontSize: 14,
    color: '#555',
    marginBottom: 8,
    lineHeight: 20,
  },
  messageDate: {
    fontSize: 12,
    color: '#666',
  },
  notificationMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  notificationBadge: {
    backgroundColor: '#2196F3',
    color: 'white',
    fontSize: 12,
    fontWeight: '500',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
  },
  testInstructions: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 20,
  },
  instructionText: {
    fontSize: 14,
    color: '#555',
    lineHeight: 20,
    marginBottom: 12,
  },
  codeText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: '#333',
    backgroundColor: '#f0f0f0',
    padding: 12,
    borderRadius: 4,
    lineHeight: 16,
  },
});