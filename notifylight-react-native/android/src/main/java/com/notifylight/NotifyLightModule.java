package com.notifylight;

import android.app.Application;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.messaging.FirebaseMessaging;

import org.json.JSONException;
import org.json.JSONObject;

public class NotifyLightModule extends ReactContextBaseJavaModule {
    private static final String TAG = "NotifyLight";
    private static final String MODULE_NAME = "NotifyLightModule";
    
    // Event names (must match iOS constants)
    private static final String EVENT_TOKEN_RECEIVED = "NotifyLightTokenReceived";
    private static final String EVENT_TOKEN_REFRESH = "NotifyLightTokenRefresh";
    private static final String EVENT_NOTIFICATION_RECEIVED = "NotifyLightNotificationReceived";
    private static final String EVENT_NOTIFICATION_OPENED = "NotifyLightNotificationOpened";
    private static final String EVENT_REGISTRATION_ERROR = "NotifyLightRegistrationError";
    
    // Intent actions
    private static final String ACTION_TOKEN_RECEIVED = "com.notifylight.TOKEN_RECEIVED";
    private static final String ACTION_TOKEN_REFRESH = "com.notifylight.TOKEN_REFRESH";
    private static final String ACTION_NOTIFICATION_RECEIVED = "com.notifylight.NOTIFICATION_RECEIVED";
    private static final String ACTION_NOTIFICATION_OPENED = "com.notifylight.NOTIFICATION_OPENED";
    
    private ReactApplicationContext reactContext;
    private String currentToken;
    private boolean isInitialized = false;
    private boolean showNotificationsWhenInForeground = false;
    private BroadcastReceiver notificationReceiver;

    public NotifyLightModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        setupBroadcastReceiver();
    }

    @Override
    @NonNull
    public String getName() {
        return MODULE_NAME;
    }

    @ReactMethod
    public void initialize(ReadableMap options, Promise promise) {
        try {
            Log.d(TAG, "Initializing NotifyLight module");
            
            if (isInitialized) {
                Log.i(TAG, "NotifyLight already initialized");
                promise.resolve(createSuccessResponse());
                return;
            }
            
            // Parse options
            if (options.hasKey("showNotificationsWhenInForeground")) {
                showNotificationsWhenInForeground = options.getBoolean("showNotificationsWhenInForeground");
            }
            
            // Initialize FCM
            initializeFCM();
            
            isInitialized = true;
            Log.i(TAG, "NotifyLight initialized successfully");
            promise.resolve(createSuccessResponse());
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize NotifyLight", e);
            promise.reject("INIT_ERROR", e.getMessage(), e);
        }
    }

    @ReactMethod
    public void requestPermissions(Promise promise) {
        // Android doesn't require explicit permission request for FCM
        // Permissions are handled through the manifest
        WritableMap response = Arguments.createMap();
        response.putBoolean("granted", true);
        response.putBoolean("alert", true);
        response.putBoolean("sound", true);
        response.putBoolean("badge", true);
        promise.resolve(response);
    }

    @ReactMethod
    public void getToken(Promise promise) {
        if (currentToken != null) {
            promise.resolve(currentToken);
        } else {
            promise.reject("NO_TOKEN", "No token available");
        }
    }

    // Public methods for service integration
    public static void handleTokenReceived(Context context, String token) {
        Log.d(TAG, "Token received: " + token.substring(0, Math.min(20, token.length())) + "...");
        
        Intent intent = new Intent(ACTION_TOKEN_RECEIVED);
        intent.putExtra("token", token);
        context.sendBroadcast(intent);
    }

    public static void handleTokenRefresh(Context context, String token) {
        Log.d(TAG, "Token refreshed: " + token.substring(0, Math.min(20, token.length())) + "...");
        
        Intent intent = new Intent(ACTION_TOKEN_REFRESH);
        intent.putExtra("token", token);
        context.sendBroadcast(intent);
    }

    public static void handleNotificationReceived(Context context, String title, String body, Bundle data) {
        Log.d(TAG, "Notification received in foreground");
        
        Intent intent = new Intent(ACTION_NOTIFICATION_RECEIVED);
        intent.putExtra("title", title);
        intent.putExtra("body", body);
        intent.putExtra("data", data);
        context.sendBroadcast(intent);
    }

    public static void handleNotificationOpened(Context context, String title, String body, Bundle data) {
        Log.d(TAG, "Notification opened");
        
        Intent intent = new Intent(ACTION_NOTIFICATION_OPENED);
        intent.putExtra("title", title);
        intent.putExtra("body", body);
        intent.putExtra("data", data);
        context.sendBroadcast(intent);
    }

    // Private methods
    private void initializeFCM() {
        FirebaseMessaging.getInstance().getToken()
            .addOnCompleteListener(new OnCompleteListener<String>() {
                @Override
                public void onComplete(@NonNull Task<String> task) {
                    if (!task.isSuccessful()) {
                        Log.w(TAG, "Fetching FCM registration token failed", task.getException());
                        sendRegistrationError("Failed to get FCM token: " + task.getException().getMessage());
                        return;
                    }

                    // Get new FCM registration token
                    String token = task.getResult();
                    Log.d(TAG, "FCM registration token: " + token.substring(0, Math.min(20, token.length())) + "...");
                    
                    currentToken = token;
                    sendTokenReceived(token);
                }
            });
    }

    private void setupBroadcastReceiver() {
        notificationReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (action == null) return;

                switch (action) {
                    case ACTION_TOKEN_RECEIVED:
                        String receivedToken = intent.getStringExtra("token");
                        if (receivedToken != null) {
                            currentToken = receivedToken;
                            sendTokenReceived(receivedToken);
                        }
                        break;
                        
                    case ACTION_TOKEN_REFRESH:
                        String refreshedToken = intent.getStringExtra("token");
                        if (refreshedToken != null) {
                            currentToken = refreshedToken;
                            sendTokenRefresh(refreshedToken);
                        }
                        break;
                        
                    case ACTION_NOTIFICATION_RECEIVED:
                        WritableMap receivedNotification = parseNotificationIntent(intent);
                        sendNotificationReceived(receivedNotification);
                        break;
                        
                    case ACTION_NOTIFICATION_OPENED:
                        WritableMap openedNotification = parseNotificationIntent(intent);
                        sendNotificationOpened(openedNotification);
                        break;
                }
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_TOKEN_RECEIVED);
        filter.addAction(ACTION_TOKEN_REFRESH);
        filter.addAction(ACTION_NOTIFICATION_RECEIVED);
        filter.addAction(ACTION_NOTIFICATION_OPENED);
        
        reactContext.registerReceiver(notificationReceiver, filter);
    }

    private WritableMap parseNotificationIntent(Intent intent) {
        WritableMap notification = Arguments.createMap();
        
        String title = intent.getStringExtra("title");
        String body = intent.getStringExtra("body");
        Bundle data = intent.getBundleExtra("data");
        
        notification.putString("title", title != null ? title : "");
        notification.putString("body", body != null ? body : "");
        notification.putString("message", body != null ? body : ""); // Alias for consistency
        
        // Convert Bundle to WritableMap
        WritableMap dataMap = Arguments.createMap();
        if (data != null) {
            for (String key : data.keySet()) {
                Object value = data.get(key);
                if (value instanceof String) {
                    dataMap.putString(key, (String) value);
                } else if (value instanceof Integer) {
                    dataMap.putInt(key, (Integer) value);
                } else if (value instanceof Double) {
                    dataMap.putDouble(key, (Double) value);
                } else if (value instanceof Boolean) {
                    dataMap.putBoolean(key, (Boolean) value);
                }
            }
        }
        notification.putMap("data", dataMap);
        
        // Add metadata
        notification.putString("id", dataMap.hasKey("id") ? dataMap.getString("id") : String.valueOf(System.currentTimeMillis()));
        notification.putString("platform", "android");
        notification.putDouble("receivedAt", System.currentTimeMillis());
        
        return notification;
    }

    private void sendTokenReceived(String token) {
        sendEvent(EVENT_TOKEN_RECEIVED, token);
    }

    private void sendTokenRefresh(String token) {
        sendEvent(EVENT_TOKEN_REFRESH, token);
    }

    private void sendNotificationReceived(WritableMap notification) {
        sendEvent(EVENT_NOTIFICATION_RECEIVED, notification);
    }

    private void sendNotificationOpened(WritableMap notification) {
        sendEvent(EVENT_NOTIFICATION_OPENED, notification);
    }

    private void sendRegistrationError(String message) {
        WritableMap error = Arguments.createMap();
        error.putString("message", message);
        error.putInt("code", -1);
        sendEvent(EVENT_REGISTRATION_ERROR, error);
    }

    private void sendEvent(String eventName, Object data) {
        if (reactContext.hasActiveCatalystInstance()) {
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit(eventName, data);
        }
    }

    private WritableMap createSuccessResponse() {
        WritableMap response = Arguments.createMap();
        response.putBoolean("success", true);
        return response;
    }

    @Override
    public void onCatalystInstanceDestroy() {
        super.onCatalystInstanceDestroy();
        if (notificationReceiver != null) {
            try {
                reactContext.unregisterReceiver(notificationReceiver);
            } catch (Exception e) {
                Log.w(TAG, "Failed to unregister receiver", e);
            }
        }
    }
}