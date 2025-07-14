// Example React Native App using NotifyLight SDK

import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Alert,
  ScrollView,
  TouchableOpacity,
  SafeAreaView,
} from 'react-native';

import NotifyLight, { 
  NOTIFICATION_TYPES, 
  APP_STATES, 
  ERROR_CODES 
} from 'notifylight-react-native';

export default function App() {
  const [isInitialized, setIsInitialized] = useState(false);
  const [token, setToken] = useState(null);
  const [notifications, setNotifications] = useState([]);
  const [status, setStatus] = useState('Initializing...');

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
      const unsubscribe = NotifyLight.onNotification((type, data) => {
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

      // Get initial token
      try {
        const initialToken = await NotifyLight.getToken();
        setToken(initialToken);
      } catch (error) {
        console.log('No initial token available');
      }

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
    console.log('Notification received:', data);
    
    // Add to notifications list
    const notification = {
      id: data.id,
      title: data.title,
      message: data.message,
      type: 'received',
      timestamp: new Date().toLocaleTimeString(),
      appState: data.appState,
    };
    
    setNotifications(prev => [notification, ...prev.slice(0, 9)]); // Keep last 10
    
    // Show in-app alert for foreground notifications
    if (data.appState === APP_STATES.FOREGROUND) {
      Alert.alert(
        data.title || 'Notification',
        data.message,
        [{ text: 'OK' }]
      );
    }
  };

  const handleNotificationOpened = (data) => {
    console.log('Notification opened:', data);
    
    // Add to notifications list
    const notification = {
      id: data.id,
      title: data.title,
      message: data.message,
      type: 'opened',
      timestamp: new Date().toLocaleTimeString(),
      appState: data.appState,
    };
    
    setNotifications(prev => [notification, ...prev.slice(0, 9)]);
    
    // Handle custom data
    if (data.data && data.data.screen) {
      Alert.alert(
        'Navigation',
        `Would navigate to: ${data.data.screen}`,
        [{ text: 'OK' }]
      );
    } else {
      Alert.alert(
        'Notification Opened',
        `${data.title}\n\n${data.message}`,
        [{ text: 'OK' }]
      );
    }
  };

  const handleTokenUpdate = (newToken) => {
    console.log('Token updated:', newToken);
    setToken(newToken);
    setStatus('Device registered successfully');
  };

  const handleRegistrationError = (error) => {
    console.error('Registration error:', error);
    setStatus(`Registration failed: ${error.message}`);
    
    Alert.alert(
      'Registration Error',
      error.message,
      [{ text: 'OK' }]
    );
  };

  const requestPermissions = async () => {
    try {
      const permissions = await NotifyLight.requestPermissions();
      Alert.alert(
        'Permissions Result',
        `Granted: ${permissions.granted}`,
        [{ text: 'OK' }]
      );
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  const manualRegister = async () => {
    try {
      setStatus('Registering device...');
      await NotifyLight.register();
      setStatus('Device registered successfully');
    } catch (error) {
      setStatus(`Registration failed: ${error.message}`);
      Alert.alert('Registration Error', error.message);
    }
  };

  const getTokenInfo = async () => {
    try {
      const currentToken = await NotifyLight.getToken();
      Alert.alert(
        'Device Token',
        `${currentToken.substring(0, 50)}...`,
        [{ text: 'OK' }]
      );
    } catch (error) {
      Alert.alert('Error', error.message);
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.scrollView}>
        <Text style={styles.title}>NotifyLight Demo</Text>
        
        <View style={styles.statusContainer}>
          <Text style={styles.statusLabel}>Status:</Text>
          <Text style={[styles.statusText, { color: isInitialized ? 'green' : 'orange' }]}>
            {status}
          </Text>
        </View>

        {token && (
          <View style={styles.tokenContainer}>
            <Text style={styles.statusLabel}>Device Token:</Text>
            <Text style={styles.tokenText}>
              {token.substring(0, 30)}...
            </Text>
          </View>
        )}

        <View style={styles.buttonContainer}>
          <TouchableOpacity style={styles.button} onPress={requestPermissions}>
            <Text style={styles.buttonText}>Request Permissions</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.button} onPress={manualRegister}>
            <Text style={styles.buttonText}>Manual Register</Text>
          </TouchableOpacity>
          
          <TouchableOpacity style={styles.button} onPress={getTokenInfo}>
            <Text style={styles.buttonText}>Show Token</Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.sectionTitle}>Recent Notifications ({notifications.length})</Text>
        
        {notifications.length === 0 ? (
          <Text style={styles.emptyText}>
            No notifications yet. Send a test notification from your server.
          </Text>
        ) : (
          notifications.map((notification, index) => (
            <View key={`${notification.id}-${index}`} style={styles.notificationItem}>
              <View style={styles.notificationHeader}>
                <Text style={styles.notificationTitle}>
                  {notification.title || 'No Title'}
                </Text>
                <Text style={styles.notificationTime}>
                  {notification.timestamp}
                </Text>
              </View>
              <Text style={styles.notificationMessage}>
                {notification.message}
              </Text>
              <View style={styles.notificationMeta}>
                <Text style={[styles.notificationBadge, { 
                  backgroundColor: notification.type === 'opened' ? '#4CAF50' : '#2196F3' 
                }]}>
                  {notification.type}
                </Text>
                <Text style={styles.notificationState}>
                  {notification.appState}
                </Text>
              </View>
            </View>
          ))
        )}

        <View style={styles.testInstructions}>
          <Text style={styles.sectionTitle}>Test Instructions</Text>
          <Text style={styles.instructionText}>
            1. Make sure your NotifyLight server is running{'\n'}
            2. Update the API URL and API key in this code{'\n'}
            3. Build and run on a physical device{'\n'}
            4. Send a test notification from your server:{'\n'}
          </Text>
          <Text style={styles.codeText}>
            curl -X POST https://your-server.com/notify \{'\n'}
            {'  '}-H "Content-Type: application/json" \{'\n'}
            {'  '}-H "X-API-Key: your-api-key" \{'\n'}
            {'  '}-d '{"{"}{"title": "Test", "message": "Hello!"{"}"}'
          </Text>
        </View>
      </ScrollView>
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
  tokenContainer: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 16,
  },
  tokenText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: '#333',
    backgroundColor: '#f0f0f0',
    padding: 8,
    borderRadius: 4,
  },
  buttonContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 20,
  },
  button: {
    backgroundColor: '#2196F3',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 6,
    marginRight: 8,
    marginBottom: 8,
  },
  buttonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: '500',
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
  notificationItem: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginBottom: 8,
    borderLeftWidth: 4,
    borderLeftColor: '#2196F3',
  },
  notificationHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  notificationTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    flex: 1,
  },
  notificationTime: {
    fontSize: 12,
    color: '#666',
  },
  notificationMessage: {
    fontSize: 14,
    color: '#555',
    marginBottom: 8,
    lineHeight: 20,
  },
  notificationMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  notificationBadge: {
    color: 'white',
    fontSize: 12,
    fontWeight: '500',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
  },
  notificationState: {
    fontSize: 12,
    color: '#666',
    fontStyle: 'italic',
  },
  testInstructions: {
    backgroundColor: 'white',
    padding: 16,
    borderRadius: 8,
    marginTop: 20,
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