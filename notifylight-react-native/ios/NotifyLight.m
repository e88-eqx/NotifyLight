//
//  NotifyLight.m
//  NotifyLight React Native SDK
//
//  Copyright © 2025 NotifyLight. All rights reserved.
//

#import "NotifyLight.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <UserNotifications/UserNotifications.h>

static NSString *const kNotifyLightTokenReceived = @"NotifyLightTokenReceived";
static NSString *const kNotifyLightTokenRefresh = @"NotifyLightTokenRefresh";
static NSString *const kNotifyLightNotificationReceived = @"NotifyLightNotificationReceived";
static NSString *const kNotifyLightNotificationOpened = @"NotifyLightNotificationOpened";
static NSString *const kNotifyLightRegistrationError = @"NotifyLightRegistrationError";

@implementation NotifyLight

static NotifyLight *sharedInstance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isInitialized = NO;
        _showNotificationsWhenInForeground = NO;
        _currentToken = nil;
        
        // Set up notification center delegate
        [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    }
    return self;
}

#pragma mark - RCTBridgeModule

RCT_EXPORT_MODULE(NotifyLightModule);

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[
        kNotifyLightTokenReceived,
        kNotifyLightTokenRefresh,
        kNotifyLightNotificationReceived,
        kNotifyLightNotificationOpened,
        kNotifyLightRegistrationError
    ];
}

#pragma mark - React Native Methods

RCT_EXPORT_METHOD(initialize:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initializeWithOptions:options];
            resolve(@{@"success": @YES});
        });
    } @catch (NSException *exception) {
        reject(@"INIT_ERROR", exception.reason, nil);
    }
}

RCT_EXPORT_METHOD(requestPermissions:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [self requestPermissionsWithResolver:resolve rejecter:reject];
}

RCT_EXPORT_METHOD(getToken:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [self getTokenWithResolver:resolve rejecter:reject];
}

#pragma mark - Public Methods

- (void)initializeWithOptions:(NSDictionary *)options {
    if (self.isInitialized) {
        RCTLogInfo(@"NotifyLight already initialized");
        return;
    }
    
    // Parse options
    self.showNotificationsWhenInForeground = [options[@"showNotificationsWhenInForeground"] boolValue];
    
    // Register for notifications
    [self registerForNotifications];
    
    self.isInitialized = YES;
    RCTLogInfo(@"NotifyLight initialized successfully");
}

- (void)requestPermissionsWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
    
    [center requestAuthorizationWithOptions:options
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                reject(@"PERMISSION_ERROR", error.localizedDescription, error);
            } else {
                resolve(@{
                    @"granted": @(granted),
                    @"alert": @(granted),
                    @"sound": @(granted),
                    @"badge": @(granted)
                });
                
                if (granted) {
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                }
            }
        });
    }];
}

- (void)getTokenWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject {
    if (self.currentToken) {
        resolve(self.currentToken);
    } else {
        reject(@"NO_TOKEN", @"No token available", nil);
    }
}

#pragma mark - Internal Methods

- (void)registerForNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    // Check current authorization status
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                [[UIApplication sharedApplication] registerForRemoteNotifications];
            } else if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                // Will be handled by requestPermissions if needed
                RCTLogInfo(@"Notification permissions not determined");
            } else {
                RCTLogWarn(@"Notification permissions denied");
            }
        });
    }];
}

- (void)handleTokenReceived:(NSString *)token {
    self.currentToken = token;
    [self sendEventWithName:kNotifyLightTokenReceived body:token];
}

- (void)handleTokenRefresh:(NSString *)token {
    self.currentToken = token;
    [self sendEventWithName:kNotifyLightTokenRefresh body:token];
}

- (void)handleNotificationReceived:(NSDictionary *)notification {
    [self sendEventWithName:kNotifyLightNotificationReceived body:notification];
}

- (void)handleNotificationOpened:(NSDictionary *)notification {
    [self sendEventWithName:kNotifyLightNotificationOpened body:notification];
}

- (void)handleRegistrationError:(NSError *)error {
    NSDictionary *errorDict = @{
        @"message": error.localizedDescription ?: @"Unknown error",
        @"code": @(error.code)
    };
    [self sendEventWithName:kNotifyLightRegistrationError body:errorDict];
}

#pragma mark - UIApplication Delegate Methods (to be called from AppDelegate)

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [self deviceTokenToString:deviceToken];
    RCTLogInfo(@"APNs token received: %@", [token substringToIndex:MIN(20, token.length)]);
    [self handleTokenReceived:token];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    RCTLogError(@"Failed to register for remote notifications: %@", error.localizedDescription);
    [self handleRegistrationError:error];
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    RCTLogInfo(@"Remote notification received");
    
    // Parse notification data
    NSDictionary *notification = [self parseNotificationData:userInfo];
    
    // Handle based on app state
    UIApplicationState appState = [UIApplication sharedApplication].applicationState;
    if (appState == UIApplicationStateActive) {
        [self handleNotificationReceived:notification];
    } else {
        [self handleNotificationOpened:notification];
    }
    
    if (completionHandler) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    NSDictionary *notificationData = [self parseNotificationData:notification.request.content.userInfo];
    [self handleNotificationReceived:notificationData];
    
    // Show notification if configured to do so
    UNNotificationPresentationOptions options = UNNotificationPresentationOptionNone;
    if (self.showNotificationsWhenInForeground) {
        if (@available(iOS 14.0, *)) {
            options = UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound;
        } else {
            options = UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound;
        }
    }
    
    completionHandler(options);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)(void))completionHandler {
    
    NSDictionary *notificationData = [self parseNotificationData:response.notification.request.content.userInfo];
    [self handleNotificationOpened:notificationData];
    
    completionHandler();
}

#pragma mark - Helper Methods

- (NSString *)deviceTokenToString:(NSData *)deviceToken {
    const unsigned char *dataBuffer = (const unsigned char *)[deviceToken bytes];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:([deviceToken length] * 2)];
    
    for (int i = 0; i < [deviceToken length]; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    }
    
    return [hexString copy];
}

- (NSDictionary *)parseNotificationData:(NSDictionary *)userInfo {
    NSMutableDictionary *notification = [NSMutableDictionary dictionary];
    
    // Extract APS data
    NSDictionary *aps = userInfo[@"aps"];
    if (aps) {
        NSDictionary *alert = aps[@"alert"];
        if ([alert isKindOfClass:[NSDictionary class]]) {
            notification[@"title"] = alert[@"title"] ?: @"";
            notification[@"body"] = alert[@"body"] ?: @"";
        } else if ([alert isKindOfClass:[NSString class]]) {
            notification[@"body"] = alert;
        }
        
        notification[@"badge"] = aps[@"badge"] ?: @0;
        notification[@"sound"] = aps[@"sound"] ?: @"";
    }
    
    // Extract custom data
    NSMutableDictionary *customData = [NSMutableDictionary dictionary];
    for (NSString *key in userInfo.allKeys) {
        if (![key isEqualToString:@"aps"]) {
            customData[key] = userInfo[key];
        }
    }
    notification[@"data"] = customData;
    
    // Add metadata
    notification[@"id"] = customData[@"id"] ?: [[NSUUID UUID] UUIDString];
    notification[@"platform"] = @"ios";
    notification[@"receivedAt"] = @([[NSDate date] timeIntervalSince1970] * 1000);
    
    return [notification copy];
}

@end