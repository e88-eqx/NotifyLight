import React, { useState, useEffect, useRef } from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  Alert,
  Clipboard,
  Modal,
  Switch,
  Platform,
  AppState,
} from 'react-native';
import NetInfo from '@react-native-community/netinfo';
import AsyncStorage from '@react-native-async-storage/async-storage';
import DeviceInfo from 'react-native-device-info';

import NotifyLight, { 
  NOTIFICATION_TYPES, 
  MESSAGE_TYPES,
  APP_STATES, 
  ERROR_CODES,
  InAppModal 
} from 'notifylight-react-native';

const STORAGE_KEYS = {
  API_URL: '@NotifyLightTest:apiUrl',
  API_KEY: '@NotifyLightTest:apiKey',
  USER_ID: '@NotifyLightTest:userId',
  AUTO_REGISTER: '@NotifyLightTest:autoRegister',
};

const DEFAULT_CONFIG = {
  apiUrl: 'http://localhost:3000',
  apiKey: 'test-api-key-123',
  userId: 'test-user-' + Math.random().toString(36).substr(2, 9),
  autoRegister: true,
};

export default function App() {
  // State for configuration
  const [config, setConfig] = useState(DEFAULT_CONFIG);
  const [showSettings, setShowSettings] = useState(false);
  
  // State for SDK status
  const [isInitialized, setIsInitialized] = useState(false);
  const [currentToken, setCurrentToken] = useState(null);
  const [connectionStatus, setConnectionStatus] = useState('unknown');
  const [networkStatus, setNetworkStatus] = useState({ isConnected: false, type: 'unknown' });
  
  // State for logs and testing
  const [logs, setLogs] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [messages, setMessages] = useState([]);
  const [showLogs, setShowLogs] = useState(false);
  const [testResults, setTestResults] = useState({});
  
  // State for in-app messages
  const [showInAppModal, setShowInAppModal] = useState(false);
  const [currentInAppMessage, setCurrentInAppMessage] = useState(null);
  
  // Refs
  const appState = useRef(AppState.currentState);
  const logCounter = useRef(0);
  
  useEffect(() => {
    loadStoredConfig();
    setupNetworkMonitoring();
    setupAppStateListener();
    
    return () => {
      NotifyLight.cleanup();
    };
  }, []);
  
  useEffect(() => {
    if (Object.keys(config).length > 0) {
      saveConfig();
    }
  }, [config]);
  
  // Load stored configuration
  const loadStoredConfig = async () => {
    try {
      const stored = {};
      for (const [key, storageKey] of Object.entries(STORAGE_KEYS)) {
        const value = await AsyncStorage.getItem(storageKey);
        if (value !== null) {
          stored[key] = key === 'autoRegister' ? JSON.parse(value) : value;
        }
      }
      
      if (Object.keys(stored).length > 0) {
        setConfig(prev => ({ ...prev, ...stored }));
      }
    } catch (error) {
      addLog('Error loading config: ' + error.message, 'error');
    }
  };
  
  // Save configuration
  const saveConfig = async () => {
    try {
      for (const [key, value] of Object.entries(config)) {
        if (STORAGE_KEYS[key]) {
          await AsyncStorage.setItem(
            STORAGE_KEYS[key], 
            typeof value === 'boolean' ? JSON.stringify(value) : value
          );
        }
      }
    } catch (error) {
      addLog('Error saving config: ' + error.message, 'error');
    }
  };
  
  // Setup network monitoring
  const setupNetworkMonitoring = () => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setNetworkStatus({
        isConnected: state.isConnected,
        type: state.type,
      });
      addLog(`Network: ${state.isConnected ? 'Connected' : 'Disconnected'} (${state.type})`, 'info');
    });
    
    return unsubscribe;
  };
  
  // Setup app state listener
  const setupAppStateListener = () => {
    const handleAppStateChange = (nextAppState) => {
      addLog(`App state changed: ${appState.current} -> ${nextAppState}`, 'info');
      appState.current = nextAppState;
    };
    
    const subscription = AppState.addEventListener('change', handleAppStateChange);
    return () => subscription?.remove();
  };
  
  // Logging utility
  const addLog = (message, type = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    const newLog = {
      id: ++logCounter.current,
      timestamp,
      message,
      type,
    };
    
    setLogs(prev => [newLog, ...prev.slice(0, 99)]); // Keep last 100 logs
    console.log(`[${timestamp}] [${type.toUpperCase()}] ${message}`);
  };
  
  // Initialize NotifyLight SDK
  const initializeSDK = async () => {
    try {
      addLog('Initializing NotifyLight SDK...', 'info');
      setConnectionStatus('connecting');
      
      await NotifyLight.initialize({
        apiUrl: config.apiUrl,
        apiKey: config.apiKey,
        userId: config.userId,
        autoRegister: config.autoRegister,
        requestPermissions: true,
        showNotificationsWhenInForeground: false,
        enableLogs: true,
      });
      
      setupNotificationHandlers();
      setIsInitialized(true);
      setConnectionStatus('connected');
      addLog('✅ NotifyLight initialized successfully', 'success');
      
      // Get device info
      const deviceInfo = {
        brand: DeviceInfo.getBrand(),
        model: DeviceInfo.getModel(),
        systemVersion: DeviceInfo.getSystemVersion(),
        buildNumber: DeviceInfo.getBuildNumber(),
      };
      addLog(`Device: ${deviceInfo.brand} ${deviceInfo.model} (${deviceInfo.systemVersion})`, 'info');
      
    } catch (error) {
      setConnectionStatus('error');
      addLog('❌ SDK initialization failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, initialization: 'failed' }));
    }
  };
  
  // Setup notification event handlers
  const setupNotificationHandlers = () => {
    // Main notification handler
    const unsubscribeNotifications = NotifyLight.onNotification((type, data) => {
      const notification = {
        id: Date.now(),
        type,
        data,
        timestamp: new Date().toLocaleTimeString(),
        appState: appState.current,
      };
      
      setNotifications(prev => [notification, ...prev.slice(0, 49)]); // Keep last 50
      
      switch (type) {
        case NOTIFICATION_TYPES.RECEIVED:
          addLog(`📱 Notification received: ${data.title}`, 'success');
          setTestResults(prev => ({ ...prev, pushReceived: 'passed' }));
          break;
          
        case NOTIFICATION_TYPES.OPENED:
          addLog(`👆 Notification opened: ${data.title}`, 'success');
          setTestResults(prev => ({ ...prev, pushOpened: 'passed' }));
          break;
          
        case NOTIFICATION_TYPES.TOKEN_RECEIVED:
        case NOTIFICATION_TYPES.TOKEN_REFRESH:
          setCurrentToken(data.token);
          addLog(`🔑 Token ${type === NOTIFICATION_TYPES.TOKEN_REFRESH ? 'refreshed' : 'received'}: ${data.token.substring(0, 20)}...`, 'success');
          setTestResults(prev => ({ ...prev, tokenRegistration: 'passed' }));
          break;
          
        case NOTIFICATION_TYPES.REGISTRATION_ERROR:
          addLog(`❌ Registration error: ${data.message}`, 'error');
          setTestResults(prev => ({ ...prev, tokenRegistration: 'failed' }));
          break;
      }
    });
    
    // Message handler for in-app messages
    const unsubscribeMessages = NotifyLight.onMessageDisplayed((type, data) => {
      switch (type) {
        case MESSAGE_TYPES.DISPLAYED:
          addLog(`💬 In-app message displayed: ${data.message.title}`, 'success');
          setCurrentInAppMessage(data.message);
          setShowInAppModal(true);
          setTestResults(prev => ({ ...prev, inAppMessages: 'passed' }));
          break;
          
        case MESSAGE_TYPES.ACTION_PRESSED:
          addLog(`🔘 Message action pressed: ${data.action.title}`, 'info');
          break;
          
        case MESSAGE_TYPES.DISMISSED:
          addLog(`✖️ Message dismissed: ${data.message.title}`, 'info');
          setShowInAppModal(false);
          break;
          
        case MESSAGE_TYPES.FETCH_SUCCESS:
          addLog(`📥 Fetched ${data.count} messages`, 'success');
          setMessages(data.messages);
          break;
          
        case MESSAGE_TYPES.FETCH_ERROR:
          addLog(`❌ Message fetch failed: ${data.error}`, 'error');
          setTestResults(prev => ({ ...prev, inAppMessages: 'failed' }));
          break;
      }
    });
    
    return () => {
      unsubscribeNotifications();
      unsubscribeMessages();
    };
  };
  
  // Test functions
  const testPushPermissions = async () => {
    try {
      addLog('Testing push permissions...', 'info');
      const result = await NotifyLight.requestPermissions();
      addLog(`Push permissions: ${JSON.stringify(result)}`, result.granted ? 'success' : 'warning');
      setTestResults(prev => ({ ...prev, permissions: result.granted ? 'passed' : 'failed' }));
    } catch (error) {
      addLog('❌ Permission test failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, permissions: 'failed' }));
    }
  };
  
  const testTokenRetrieval = async () => {
    try {
      addLog('Testing token retrieval...', 'info');
      const token = await NotifyLight.getToken();
      if (token) {
        setCurrentToken(token);
        addLog(`✅ Token retrieved: ${token.substring(0, 20)}...`, 'success');
        setTestResults(prev => ({ ...prev, tokenRetrieval: 'passed' }));
      } else {
        addLog('⚠️ No token available', 'warning');
        setTestResults(prev => ({ ...prev, tokenRetrieval: 'failed' }));
      }
    } catch (error) {
      addLog('❌ Token retrieval failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, tokenRetrieval: 'failed' }));
    }
  };
  
  const testInAppMessages = async () => {
    try {
      addLog('Testing in-app messages...', 'info');
      const result = await NotifyLight.checkForMessages();
      addLog(`✅ Message check completed. Found ${result.messages.length} messages`, 'success');
      setTestResults(prev => ({ ...prev, messageCheck: 'passed' }));
    } catch (error) {
      addLog('❌ Message check failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, messageCheck: 'failed' }));
    }
  };
  
  const testCustomMessage = () => {
    try {
      addLog('Showing custom test message...', 'info');
      NotifyLight.showMessage({
        id: 'test-' + Date.now(),
        title: 'Test Message',
        message: 'This is a test in-app message triggered from the test app.',
        actions: [
          { id: 'ok', title: 'OK', style: 'primary' },
          { id: 'cancel', title: 'Cancel', style: 'secondary' }
        ]
      });
      setTestResults(prev => ({ ...prev, customMessage: 'passed' }));
    } catch (error) {
      addLog('❌ Custom message failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, customMessage: 'failed' }));
    }
  };
  
  const testNetworkConnectivity = async () => {
    try {
      addLog('Testing network connectivity...', 'info');
      
      // Test with a simple fetch to the configured server
      const response = await fetch(`${config.apiUrl}/health`, {
        method: 'GET',
        timeout: 5000,
      });
      
      if (response.ok) {
        addLog('✅ Server connectivity test passed', 'success');
        setTestResults(prev => ({ ...prev, serverConnectivity: 'passed' }));
      } else {
        addLog(`⚠️ Server responded with status: ${response.status}`, 'warning');
        setTestResults(prev => ({ ...prev, serverConnectivity: 'warning' }));
      }
    } catch (error) {
      addLog('❌ Network connectivity test failed: ' + error.message, 'error');
      setTestResults(prev => ({ ...prev, serverConnectivity: 'failed' }));
    }
  };
  
  const runAllTests = async () => {
    addLog('🧪 Running all tests...', 'info');
    setTestResults({});
    
    if (!isInitialized) {
      await initializeSDK();
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    await testPushPermissions();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    await testTokenRetrieval();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    await testNetworkConnectivity();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    await testInAppMessages();
    await new Promise(resolve => setTimeout(resolve, 500));
    
    testCustomMessage();
    
    addLog('🏁 All tests completed', 'info');
  };
  
  const copyToken = () => {
    if (currentToken) {
      Clipboard.setString(currentToken);
      Alert.alert('Copied', 'Device token copied to clipboard');
    }
  };
  
  const clearLogs = () => {
    setLogs([]);
    setNotifications([]);
    setMessages([]);
    setTestResults({});
    addLog('Logs cleared', 'info');
  };
  
  const resetApp = async () => {
    try {
      await AsyncStorage.multiRemove(Object.values(STORAGE_KEYS));
      setConfig(DEFAULT_CONFIG);
      setIsInitialized(false);
      setCurrentToken(null);
      setConnectionStatus('unknown');
      clearLogs();
      addLog('App reset completed', 'info');
    } catch (error) {
      addLog('Reset failed: ' + error.message, 'error');
    }
  };
  
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="dark-content" backgroundColor="#f8f9fa" />
      
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>NotifyLight Test</Text>
        <View style={styles.headerButtons}>
          <TouchableOpacity
            style={[styles.headerButton, showLogs && styles.headerButtonActive]}
            onPress={() => setShowLogs(!showLogs)}
          >
            <Text style={styles.headerButtonText}>Logs</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.headerButton}
            onPress={() => setShowSettings(true)}
          >
            <Text style={styles.headerButtonText}>Settings</Text>
          </TouchableOpacity>
        </View>
      </View>
      
      {/* Status Bar */}
      <View style={styles.statusBar}>
        <StatusIndicator
          label="SDK"
          status={isInitialized ? 'connected' : connectionStatus}
        />
        <StatusIndicator
          label="Network"
          status={networkStatus.isConnected ? 'connected' : 'disconnected'}
        />
        <StatusIndicator
          label="Token"
          status={currentToken ? 'available' : 'none'}
        />
      </View>
      
      <ScrollView style={styles.content}>
        {showLogs ? (
          <LogsView logs={logs} onClear={clearLogs} />
        ) : (
          <>
            {/* Device Info */}
            <Section title="Device Information">
              <InfoRow label="Platform" value={Platform.OS} />
              <InfoRow label="User ID" value={config.userId} />
              {currentToken && (
                <TouchableOpacity onPress={copyToken}>
                  <InfoRow 
                    label="Device Token" 
                    value={`${currentToken.substring(0, 20)}...`}
                    copyable
                  />
                </TouchableOpacity>
              )}
            </Section>
            
            {/* Test Controls */}
            <Section title="SDK Tests">
              <TestButton
                title="Initialize SDK"
                onPress={initializeSDK}
                status={testResults.initialization}
                disabled={isInitialized}
              />
              <TestButton
                title="Test Permissions"
                onPress={testPushPermissions}
                status={testResults.permissions}
                disabled={!isInitialized}
              />
              <TestButton
                title="Get Token"
                onPress={testTokenRetrieval}
                status={testResults.tokenRetrieval}
                disabled={!isInitialized}
              />
              <TestButton
                title="Test Network"
                onPress={testNetworkConnectivity}
                status={testResults.serverConnectivity}
              />
              <TestButton
                title="Check Messages"
                onPress={testInAppMessages}
                status={testResults.messageCheck}
                disabled={!isInitialized}
              />
              <TestButton
                title="Show Test Message"
                onPress={testCustomMessage}
                status={testResults.customMessage}
                disabled={!isInitialized}
              />
              <TestButton
                title="🧪 Run All Tests"
                onPress={runAllTests}
                style={styles.primaryButton}
              />
            </Section>
            
            {/* Recent Activity */}
            {notifications.length > 0 && (
              <Section title={`Recent Notifications (${notifications.length})`}>
                {notifications.slice(0, 5).map(notification => (
                  <NotificationItem key={notification.id} notification={notification} />
                ))}
              </Section>
            )}
            
            {messages.length > 0 && (
              <Section title={`In-App Messages (${messages.length})`}>
                {messages.slice(0, 3).map(message => (
                  <MessageItem key={message.id} message={message} />
                ))}
              </Section>
            )}
            
            {/* Utilities */}
            <Section title="Utilities">
              <TestButton
                title="Clear All Data"
                onPress={clearLogs}
                style={styles.secondaryButton}
              />
              <TestButton
                title="Reset App"
                onPress={resetApp}
                style={styles.dangerButton}
              />
            </Section>
          </>
        )}
      </ScrollView>
      
      {/* Settings Modal */}
      <SettingsModal
        visible={showSettings}
        config={config}
        onConfigChange={setConfig}
        onClose={() => setShowSettings(false)}
      />
      
      {/* In-App Message Modal */}
      <InAppModal
        visible={showInAppModal}
        message={currentInAppMessage}
        onClose={() => setShowInAppModal(false)}
        onActionPress={(action, message) => {
          addLog(`Action pressed: ${action.title}`, 'info');
          setShowInAppModal(false);
        }}
      />
    </SafeAreaView>
  );
}

// Components
const StatusIndicator = ({ label, status }) => {
  const getStatusColor = () => {
    switch (status) {
      case 'connected':
      case 'available':
        return '#28a745';
      case 'connecting':
        return '#ffc107';
      case 'disconnected':
      case 'error':
      case 'none':
        return '#dc3545';
      default:
        return '#6c757d';
    }
  };
  
  return (
    <View style={styles.statusIndicator}>
      <View style={[styles.statusDot, { backgroundColor: getStatusColor() }]} />
      <Text style={styles.statusLabel}>{label}</Text>
    </View>
  );
};

const Section = ({ title, children }) => (
  <View style={styles.section}>
    <Text style={styles.sectionTitle}>{title}</Text>
    {children}
  </View>
);

const InfoRow = ({ label, value, copyable = false }) => (
  <View style={styles.infoRow}>
    <Text style={styles.infoLabel}>{label}:</Text>
    <Text style={styles.infoValue}>{value}</Text>
    {copyable && <Text style={styles.copyHint}>(tap to copy)</Text>}
  </View>
);

const TestButton = ({ title, onPress, status, disabled = false, style = {} }) => (
  <TouchableOpacity
    style={[
      styles.testButton,
      disabled && styles.disabledButton,
      status === 'passed' && styles.passedButton,
      status === 'failed' && styles.failedButton,
      style,
    ]}
    onPress={onPress}
    disabled={disabled}
  >
    <Text style={[styles.testButtonText, disabled && styles.disabledButtonText]}>
      {title} {status === 'passed' && '✅'} {status === 'failed' && '❌'}
    </Text>
  </TouchableOpacity>
);

const NotificationItem = ({ notification }) => (
  <View style={styles.notificationItem}>
    <Text style={styles.notificationTitle}>
      {notification.type} - {notification.timestamp}
    </Text>
    <Text style={styles.notificationMessage}>
      {notification.data.title || 'No title'}
    </Text>
    <Text style={styles.notificationState}>
      App State: {notification.appState}
    </Text>
  </View>
);

const MessageItem = ({ message }) => (
  <View style={styles.messageItem}>
    <Text style={styles.messageTitle}>{message.title}</Text>
    <Text style={styles.messageText}>{message.message}</Text>
    {message.actions && message.actions.length > 0 && (
      <Text style={styles.messageActions}>
        Actions: {message.actions.map(a => a.title).join(', ')}
      </Text>
    )}
  </View>
);

const LogsView = ({ logs, onClear }) => (
  <View style={styles.logsContainer}>
    <View style={styles.logsHeader}>
      <Text style={styles.logsTitle}>Debug Logs ({logs.length})</Text>
      <TouchableOpacity onPress={onClear} style={styles.clearButton}>
        <Text style={styles.clearButtonText}>Clear</Text>
      </TouchableOpacity>
    </View>
    <ScrollView style={styles.logsList}>
      {logs.map(log => (
        <View key={log.id} style={styles.logItem}>
          <Text style={styles.logTimestamp}>{log.timestamp}</Text>
          <Text style={[styles.logMessage, styles[`log${log.type.charAt(0).toUpperCase() + log.type.slice(1)}`]]}>
            {log.message}
          </Text>
        </View>
      ))}
    </ScrollView>
  </View>
);

const SettingsModal = ({ visible, config, onConfigChange, onClose }) => (
  <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
    <SafeAreaView style={styles.modalContainer}>
      <View style={styles.modalHeader}>
        <Text style={styles.modalTitle}>Settings</Text>
        <TouchableOpacity onPress={onClose}>
          <Text style={styles.modalCloseButton}>Done</Text>
        </TouchableOpacity>
      </View>
      
      <ScrollView style={styles.modalContent}>
        <View style={styles.settingGroup}>
          <Text style={styles.settingLabel}>API URL</Text>
          <TextInput
            style={styles.settingInput}
            value={config.apiUrl}
            onChangeText={(text) => onConfigChange(prev => ({ ...prev, apiUrl: text }))}
            placeholder="http://localhost:3000"
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
        
        <View style={styles.settingGroup}>
          <Text style={styles.settingLabel}>API Key</Text>
          <TextInput
            style={styles.settingInput}
            value={config.apiKey}
            onChangeText={(text) => onConfigChange(prev => ({ ...prev, apiKey: text }))}
            placeholder="your-api-key"
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
        
        <View style={styles.settingGroup}>
          <Text style={styles.settingLabel}>User ID</Text>
          <TextInput
            style={styles.settingInput}
            value={config.userId}
            onChangeText={(text) => onConfigChange(prev => ({ ...prev, userId: text }))}
            placeholder="user-id"
            autoCapitalize="none"
            autoCorrect={false}
          />
        </View>
        
        <View style={styles.settingGroup}>
          <View style={styles.settingRow}>
            <Text style={styles.settingLabel}>Auto Register</Text>
            <Switch
              value={config.autoRegister}
              onValueChange={(value) => onConfigChange(prev => ({ ...prev, autoRegister: value }))}
            />
          </View>
        </View>
        
        <View style={styles.settingGroup}>
          <Text style={styles.settingDescription}>
            These settings are saved locally and will persist between app launches.
            Change the API URL to point to your NotifyLight server instance.
          </Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  </Modal>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#e9ecef',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
  },
  headerButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  headerButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: '#e9ecef',
  },
  headerButtonActive: {
    backgroundColor: '#007bff',
  },
  headerButtonText: {
    fontSize: 14,
    color: '#333',
    fontWeight: '500',
  },
  statusBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingVertical: 12,
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#e9ecef',
  },
  statusIndicator: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  statusLabel: {
    fontSize: 12,
    color: '#6c757d',
    fontWeight: '500',
  },
  content: {
    flex: 1,
    padding: 16,
  },
  section: {
    marginBottom: 24,
    backgroundColor: '#ffffff',
    borderRadius: 8,
    padding: 16,
    borderWidth: 1,
    borderColor: '#e9ecef',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 12,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f3f4',
  },
  infoLabel: {
    fontSize: 14,
    color: '#6c757d',
    fontWeight: '500',
  },
  infoValue: {
    fontSize: 14,
    color: '#333',
    flex: 1,
    textAlign: 'right',
    marginRight: 8,
  },
  copyHint: {
    fontSize: 10,
    color: '#007bff',
    fontStyle: 'italic',
  },
  testButton: {
    backgroundColor: '#007bff',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 6,
    marginBottom: 8,
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: '#28a745',
  },
  secondaryButton: {
    backgroundColor: '#6c757d',
  },
  dangerButton: {
    backgroundColor: '#dc3545',
  },
  disabledButton: {
    backgroundColor: '#e9ecef',
  },
  passedButton: {
    backgroundColor: '#28a745',
  },
  failedButton: {
    backgroundColor: '#dc3545',
  },
  testButtonText: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '600',
  },
  disabledButtonText: {
    color: '#6c757d',
  },
  notificationItem: {
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f3f4',
  },
  notificationTitle: {
    fontSize: 12,
    color: '#007bff',
    fontWeight: '600',
  },
  notificationMessage: {
    fontSize: 14,
    color: '#333',
    marginVertical: 2,
  },
  notificationState: {
    fontSize: 10,
    color: '#6c757d',
  },
  messageItem: {
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#f1f3f4',
  },
  messageTitle: {
    fontSize: 14,
    color: '#333',
    fontWeight: '600',
  },
  messageText: {
    fontSize: 12,
    color: '#6c757d',
    marginVertical: 2,
  },
  messageActions: {
    fontSize: 10,
    color: '#007bff',
  },
  logsContainer: {
    flex: 1,
  },
  logsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#e9ecef',
  },
  logsTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333',
  },
  clearButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#dc3545',
    borderRadius: 4,
  },
  clearButtonText: {
    color: '#ffffff',
    fontSize: 12,
    fontWeight: '600',
  },
  logsList: {
    flex: 1,
    marginTop: 12,
  },
  logItem: {
    flexDirection: 'row',
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 4,
    marginBottom: 2,
  },
  logTimestamp: {
    fontSize: 10,
    color: '#6c757d',
    width: 60,
    marginRight: 8,
  },
  logMessage: {
    fontSize: 12,
    flex: 1,
  },
  logInfo: {
    color: '#333',
  },
  logSuccess: {
    color: '#28a745',
  },
  logWarning: {
    color: '#ffc107',
  },
  logError: {
    color: '#dc3545',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    backgroundColor: '#ffffff',
    borderBottomWidth: 1,
    borderBottomColor: '#e9ecef',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#333',
  },
  modalCloseButton: {
    fontSize: 16,
    color: '#007bff',
    fontWeight: '600',
  },
  modalContent: {
    flex: 1,
    padding: 16,
  },
  settingGroup: {
    marginBottom: 20,
  },
  settingLabel: {
    fontSize: 14,
    color: '#333',
    fontWeight: '600',
    marginBottom: 6,
  },
  settingInput: {
    borderWidth: 1,
    borderColor: '#ced4da',
    borderRadius: 6,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    backgroundColor: '#ffffff',
  },
  settingRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  settingDescription: {
    fontSize: 12,
    color: '#6c757d',
    lineHeight: 16,
    marginTop: 8,
  },
});