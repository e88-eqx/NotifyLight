//
//  NotifyLight.h
//  NotifyLight React Native SDK
//
//  Copyright © 2025 NotifyLight. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <UserNotifications/UserNotifications.h>

@interface NotifyLight : RCTEventEmitter <RCTBridgeModule, UNUserNotificationCenterDelegate>

// Public interface
+ (instancetype)sharedInstance;
- (void)initializeWithOptions:(NSDictionary *)options;
- (void)requestPermissionsWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;
- (void)getTokenWithResolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;

// Internal methods
- (void)registerForNotifications;
- (void)handleTokenReceived:(NSString *)token;
- (void)handleTokenRefresh:(NSString *)token;
- (void)handleNotificationReceived:(NSDictionary *)notification;
- (void)handleNotificationOpened:(NSDictionary *)notification;
- (void)handleRegistrationError:(NSError *)error;

@property (nonatomic, strong) NSString *currentToken;
@property (nonatomic, assign) BOOL showNotificationsWhenInForeground;
@property (nonatomic, assign) BOOL isInitialized;

@end