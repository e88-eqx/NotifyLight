package com.notifylighttest;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import com.notifylight.NotifyLightModule;
import android.os.Bundle;
import android.util.Log;

public class NotifyLightFirebaseMessagingService extends FirebaseMessagingService {
    
    private static final String TAG = "NotifyLightFCM";

    @Override
    public void onNewToken(String token) {
        super.onNewToken(token);
        Log.d(TAG, "New FCM token: " + token);
        
        // Pass token to NotifyLight SDK
        NotifyLightModule.handleTokenRefresh(this, token);
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        super.onMessageReceived(remoteMessage);
        
        Log.d(TAG, "Message received from: " + remoteMessage.getFrom());
        
        String title = "";
        String body = "";
        Bundle data = new Bundle();
        
        // Extract notification payload
        if (remoteMessage.getNotification() != null) {
            title = remoteMessage.getNotification().getTitle();
            body = remoteMessage.getNotification().getBody();
            Log.d(TAG, "Notification - Title: " + title + ", Body: " + body);
        }
        
        // Extract data payload
        if (remoteMessage.getData().size() > 0) {
            Log.d(TAG, "Message data payload: " + remoteMessage.getData());
            for (String key : remoteMessage.getData().keySet()) {
                data.putString(key, remoteMessage.getData().get(key));
            }
        }
        
        // Handle different message types
        String messageType = remoteMessage.getData().get("type");
        if ("in-app".equals(messageType)) {
            Log.d(TAG, "Handling in-app message");
            // In-app messages are handled by the SDK when the app is active
            // Background handling would need additional implementation
        } else {
            Log.d(TAG, "Handling push notification");
        }
        
        // Pass to NotifyLight SDK
        NotifyLightModule.handleNotificationReceived(this, title, body, data);
    }

    @Override
    public void onDeletedMessages() {
        super.onDeletedMessages();
        Log.d(TAG, "Messages deleted on server");
    }

    @Override
    public void onMessageSent(String msgId) {
        super.onMessageSent(msgId);
        Log.d(TAG, "Message sent: " + msgId);
    }

    @Override
    public void onSendError(String msgId, Exception exception) {
        super.onSendError(msgId, exception);
        Log.e(TAG, "Message send error: " + msgId, exception);
    }
}