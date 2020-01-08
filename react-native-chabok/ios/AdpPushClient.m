#import <React/RCTLog.h>
#import "AdpPushClient.h"

@interface PushClientManager(PushManager)
-(NSString *) getMessageIdFromPayload:(NSDictionary *)payload;
@end

@interface AdpPushClient()<PushClientManagerDelegate>

@property (nonatomic, strong) NSString* appId;
@property (nonatomic, strong) RCTPromiseResolveBlock getDeepLinkResponseCallback;
@property (nonatomic, strong) RCTPromiseResolveBlock getReferralResponseCallback;
@property (class) NSDictionary* coldStartNotificationResult;

@end

static NSString* RCTCurrentAppBackgroundState() {
    static NSDictionary *states;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        states = @{
            @(UIApplicationStateActive): @"active",
            @(UIApplicationStateBackground): @"background",
            @(UIApplicationStateInactive): @"inactive"
        };
    });

    return states[@([[UIApplication sharedApplication] applicationState])] ?: @"unknown";
}

@implementation AdpPushClient

@dynamic coldStartNotificationResult;
static NSDictionary* _coldStartNotificationResult;
BOOL _hasListeners;
NSString* _lastNotificationId;
NSString* _lastKnownState;

RCT_EXPORT_MODULE()

-(instancetype) init {
    if ((self = [super init])) {
        [PushClientManager.defaultManager addDelegate:self];
        
        _lastKnownState = RCTCurrentAppBackgroundState();

        for (NSString *name in @[UIApplicationDidBecomeActiveNotification,
                               UIApplicationDidEnterBackgroundNotification,
                               UIApplicationDidFinishLaunchingNotification]) {

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAppStateDidChange)
                                                     name:name
                                                   object:nil];
        }
    }
    return self;
}

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+(BOOL) requiresMainQueueSetup {
    return NO;
}

-(void) handleAppStateDidChange {
    NSString *newState = RCTCurrentAppBackgroundState();
    if (![newState isEqualToString:_lastKnownState]) {
        _lastKnownState = newState;
    }
    
    if (![_lastKnownState isEqualToString:@"background"]) {
        NSDictionary *lastNotification = [PushClientManager.defaultManager lastNotificationAction];
        if (lastNotification) {
            NSString *actionId = lastNotification[@"actionId"];
            if (!actionId) {
                actionId = [lastNotification[@"actionType"] lowercaseString];
                if ([actionId containsString:@"opened"]) {
                    if (@available(iOS 10.0, *)) {
                        actionId = UNNotificationDefaultActionIdentifier;
                    }
                } else {
                    if (@available(iOS 10.0, *)) {
                        actionId = UNNotificationDismissActionIdentifier;
                    }
                }
            }
            // prepare last notification
            [AdpPushClient notificationOpened:[PushClientManager.defaultManager lastNotificationData]
            actionId:actionId];
            
            // send notification event
            [self handleNotificationOpened];
        }
    }
}

// Will be called when this module's first listener is added.
-(void) startObserving {
    _hasListeners = YES;
    [self sendConnectionStatus];
    
    NSDictionary *lastNotification = [PushClientManager.defaultManager lastNotificationAction];
    if (lastNotification) {
        NSString *actionId = lastNotification[@"actionId"];
        if (!actionId) {
            actionId = [lastNotification[@"actionType"] lowercaseString];
            if ([actionId containsString:@"opened"]) {
                if (@available(iOS 10.0, *)) {
                    actionId = UNNotificationDefaultActionIdentifier;
                }
            } else {
                if (@available(iOS 10.0, *)) {
                    actionId = UNNotificationDismissActionIdentifier;
                }
            }
        }
        // prepare last notification
        [AdpPushClient notificationOpened:[PushClientManager.defaultManager lastNotificationData]
        actionId:actionId];
        
        // send notification event
        [self handleNotificationOpened];
    }
}

// Will be called when this module's last listener is removed, or on dealloc.
-(void) stopObserving {
    _hasListeners = NO;
}

#pragma mark - Register methods

RCT_EXPORT_METHOD(login:(NSString *)userId) {
    if (userId && ![userId isEqual:[NSNull null]]) {
        BOOL state = [PushClientManager.defaultManager login:userId];
        if (state) {
            RCTLogInfo(@"Registered to chabok");
        } else {
            RCTLogInfo(@"Fail to registered to chabok");
        }
    } else {
        RCTLogInfo(@"Could not register userId to chabok");
    }
}

RCT_EXPORT_METHOD(logout) {
    [PushClientManager.defaultManager logout];
}

RCT_EXPORT_METHOD(getInstallationId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *installationId = [PushClientManager.defaultManager getInstallationId];
    if (!installationId) {
        NSError *error = [NSError.alloc initWithDomain:@"Not registered"
                                                  code:500
                                              userInfo:@{
                                                         @"message":@"The installationId is null, You didn't register yet!"
                                                         }];
        reject(@"500",@"The installationId is null, You didn't register yet!",error);
    } else {
        resolve(installationId);
    }
}

RCT_EXPORT_METHOD(getUserId:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSString *userId = [PushClientManager.defaultManager userId];
    if (!userId) {
        NSError *error = [NSError.alloc initWithDomain:@"Not registered"
                                                  code:500
                                              userInfo:@{
                                                         @"message":@"The userId is null, You didn't register yet!"
                                                         }];
        reject(@"500",@"The userId is null, You didn't register yet!",error);
    } else {
        resolve(userId);
    }
}

#pragma mark - tags

RCT_EXPORT_METHOD(addTag:(NSString *) tagName resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [PushClientManager.defaultManager addTag:tagName
                                     success:^(NSInteger count) {
                                         resolve(@{@"count":@(count)});
                                     } failure:^(NSError *error) {
                                         NSString *errorCode = [NSString stringWithFormat:@"%zd",error.code];
                                         reject(errorCode,error.domain,error);
                                     }];
}
RCT_EXPORT_METHOD(addTags:(NSArray *) tagsName resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [PushClientManager.defaultManager addTags:tagsName
                                      success:^(NSInteger count) {
                                          resolve(@{@"count":@(count)});
                                      } failure:^(NSError *error) {
                                          NSString *errorCode = [NSString stringWithFormat:@"%zd",error.code];
                                          reject(errorCode,error.domain,error);
                                      }];
}

RCT_EXPORT_METHOD(removeTag:(NSString *) tagName resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [PushClientManager.defaultManager removeTag:tagName
                                        success:^(NSInteger count) {
                                            resolve(@{@"count":@(count)});
                                        } failure:^(NSError *error) {
                                            NSString *errorCode = [NSString stringWithFormat:@"%zd",error.code];
                                            reject(errorCode,error.domain,error);
                                        }];
}

RCT_EXPORT_METHOD(removeTags:(NSArray *) tagsName resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [PushClientManager.defaultManager removeTags:tagsName
                                         success:^(NSInteger count) {
                                             resolve(@{@"count":@(count)});
                                         } failure:^(NSError *error) {
                                             NSString *errorCode = [NSString stringWithFormat:@"%zd",error.code];
                                             reject(errorCode,error.domain,error);
                                         }];
}

#pragma mark - publish

//RCT_EXPORT_METHOD(publish:(NSString *) channel text:(NSString *) text resolver:(RCTPromiseResolveBlock)resolve
//                  rejecter:(RCTPromiseRejectBlock)reject) {
//  BOOL publishState = [PushClientManager.defaultManager publish:channel withText:text];
//  resolve(@[@{@"published":@(publishState)}]);
//}
//
//RCT_EXPORT_METHOD(publish:(NSString *) userId channel:(NSString *) channel text:(NSString *) text resolver:(RCTPromiseResolveBlock)resolve
//                  rejecter:(RCTPromiseRejectBlock)reject) {
//  BOOL publishState = [PushClientManager.defaultManager publish:userId toChannel:channel withText:text];
//  resolve(@[@{@"published":@(publishState)}]);
//}

RCT_EXPORT_METHOD(publish:(NSDictionary *) message resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *data = [message valueForKey:@"data"];
    NSString *userId = [message valueForKey:@"userId"];
    NSString *content = [message valueForKey:@"content"];
    NSString *channel = [message valueForKey:@"channel"];
    
    PushClientMessage *chabokMessage;
    if (data) {
        chabokMessage = [[PushClientMessage alloc] initWithMessage:content withData:data toUserId:userId channel:channel];
    } else {
        chabokMessage = [[PushClientMessage alloc] initWithMessage:content toUserId:userId channel:channel];
    }
    
    BOOL publishState = [PushClientManager.defaultManager publish:chabokMessage];
    resolve(@{@"published":@(publishState)});
}

#pragma mark - publish event

RCT_EXPORT_METHOD(publishEvent:(NSString *) eventName data:(NSDictionary *) data resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    [PushClientManager.defaultManager publishEvent:eventName data:data];
}

#pragma mark - subscribe
RCT_EXPORT_METHOD(subscribe:(NSString *) channel) {
    [PushClientManager.defaultManager subscribe:channel];
}

RCT_EXPORT_METHOD(subscribeEvent:(NSString *) eventName) {
    [PushClientManager.defaultManager subscribeEvent:eventName];
}

RCT_EXPORT_METHOD(subscribeEvent:(NSString *) eventName installationId:(NSString *) installationId) {
    if (!installationId) {
        [PushClientManager.defaultManager subscribeEvent:eventName];
    } else {
        [PushClientManager.defaultManager subscribeEvent:eventName installationId:installationId];
    }
}

#pragma mark - unsubscribe
RCT_EXPORT_METHOD(unSubscribe:(NSString *) channel) {
    [PushClientManager.defaultManager unsubscribe:channel];
}

RCT_EXPORT_METHOD(unSubscribeEvent:(NSString *) eventName) {
    [PushClientManager.defaultManager unsubscribeEvent:eventName];
}

RCT_EXPORT_METHOD(unSubscribeEvent:(NSString *) eventName installationId:(NSString *) installationId) {
    if (!installationId) {
        [PushClientManager.defaultManager unsubscribeEvent:eventName];
    } else {
        [PushClientManager.defaultManager unsubscribeEvent:eventName installationId:installationId];
    }
}

#pragma mark - badge
RCT_EXPORT_METHOD(resetBadge) {
    [PushClientManager resetBadge];
}

#pragma mark - track
RCT_EXPORT_METHOD(track:(NSString *) trackName data:(NSDictionary *) data) {
    [PushClientManager.defaultManager track:trackName data:[AdpPushClient getFormattedData:data]];
}

RCT_EXPORT_METHOD(trackPurchase:(NSString *) eventName data:(NSDictionary *) data) {
    ChabokEvent *chabokEvent = [[ChabokEvent alloc] init];

    if (![data valueForKey:@"revenue"]) {
        [NSException raise:@"Invalid revenue" format:@"Please provide a revenue."];
    }
    chabokEvent.revenue = [[data valueForKey:@"revenue"] doubleValue];
    if ([data valueForKey:@"currency"]) {
        chabokEvent.currency = [data valueForKey:@"currency"];
    }
    if ([data valueForKey:@"data"]) {
        chabokEvent.data = [AdpPushClient getFormattedData:[data valueForKey:@"data"]];
    }
    
    [PushClientManager.defaultManager trackPurchase:eventName
                                        chabokEvent:chabokEvent];
}

#pragma mark - default tracker
RCT_EXPORT_METHOD(setDefaultTracker:(NSString *) defaultTracker) {
    [PushClientManager.defaultManager setDefaultTracker:defaultTracker];;
}

#pragma mark - user attributes
RCT_EXPORT_METHOD(setUserAttributes:(NSDictionary *) attributes) {
    [PushClientManager.defaultManager setUserAttributes:[AdpPushClient getFormattedData:attributes]];
}

RCT_EXPORT_METHOD(getUserAttributes:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    resolve(PushClientManager.defaultManager.userAttributes);
}

RCT_EXPORT_METHOD(incrementUserAttribute:(NSString *) attribute value:(NSInteger) value) {
    [PushClientManager.defaultManager incrementUserAttribute:attribute value:value];
}

RCT_EXPORT_METHOD(unsetUserAttribute:(NSString *) attributeKey) {
    [PushClientManager.defaultManager unsetUserAttribute:attributeKey];
}

RCT_EXPORT_METHOD(addToUserAttributeArray:(NSString *) attributeKey attributeValue:(NSString *) attributeValue) {
    [PushClientManager.defaultManager addToUserAttributeArray:attributeKey attributeValue:attributeValue];
}

RCT_EXPORT_METHOD(removeFromUserAttributeArray:(NSString *) attributeKey attributeValue:(NSString *) attributeValue) {
    [PushClientManager.defaultManager removeFromUserAttributeArray:attributeKey attributeValue:attributeValue];
}

RCT_EXPORT_METHOD(setDefaultNotificationChannel) {
}

RCT_EXPORT_METHOD(setOnDeeplinkResponseListener:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    self.getDeepLinkResponseCallback = resolve;
}

RCT_EXPORT_METHOD(setOnReferralResponseListener:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    self.getReferralResponseCallback = resolve;
}

#pragma mark - chabok delegate methods
-(BOOL)chabokDeeplinkResponse:(NSURL *)deeplink {
    if(deeplink && self.getDeepLinkResponseCallback) {
        self.getDeepLinkResponseCallback(deeplink.absoluteString);
    }
    return NO;
}

-(void)chabokReferralResponse:(NSString *)referralId {
    if(referralId && self.getReferralResponseCallback) {
        self.getReferralResponseCallback(referralId);
    }
}

-(NSArray<NSString *> *)supportedEvents{
    return @[@"connectionStatus",@"onEvent",@"onMessage", @"ChabokMessageReceived", @"onSubscribe", @"onUnsubscribe", @"onRegister", @"notificationOpened"];
}

-(void) pushClientManagerDidReceivedMessage:(PushClientMessage *)message {
    if (self.bridge) {
        NSMutableDictionary *messageDict = [NSMutableDictionary.alloc initWithDictionary:[message toDict]];
        [messageDict setObject:message.channel forKey:@"channel"];
        
        [self sendEventWithName:@"onMessage" body:messageDict];
        [self sendEventWithName:@"ChabokMessageReceived" body:messageDict];
    }
}

-(void) pushClientManagerDidReceivedEventMessage:(EventMessage *)eventMessage {
    if (self.bridge) {
        NSDictionary *eventMessageDic =  @{
                                           @"id":eventMessage.id,
                                           @"installationId":eventMessage.deviceId,
                                           @"eventName":eventMessage.eventName
                                           };
        NSMutableDictionary *eventPayload = [NSMutableDictionary.alloc initWithDictionary:eventMessageDic];
        if (eventMessage.data) {
            [eventPayload setObject:eventMessage.data forKey:@"data"];
        }
        
        [self sendEventWithName:@"onEvent" body:[eventPayload copy]];
    }
}

-(void) pushClientManagerDidChangedServerConnectionState {
    if (self.bridge) {
        [self sendConnectionStatus];
    }
}

-(void) sendConnectionStatus {
    NSString *connectionState = @"";
    if (PushClientManager.defaultManager.connectionState == PushClientServerConnectedState) {
        connectionState = @"CONNECTED";
    } else if (PushClientManager.defaultManager.connectionState == PushClientServerConnectingState ||
               PushClientManager.defaultManager.connectionState == PushClientServerConnectingStartState) {
        connectionState = @"CONNECTING";
    } else if (PushClientManager.defaultManager.connectionState == PushClientServerDisconnectedState ||
               PushClientManager.defaultManager.connectionState == PushClientServerDisconnectedErrorState) {
        connectionState = @"DISCONNECTED";
    } else  if (PushClientManager.defaultManager.connectionState == PushClientServerSocketTimeoutState) {
        connectionState = @"SocketTimeout";
    } else {
        connectionState = @"NOT_INITIALIZED";
    }
    
    [self sendEventWithName:@"connectionStatus" body:connectionState];
}

-(void) pushClientManagerDidSubscribed:(NSString *)channel{
    [self sendEventWithName:@"onSubscribe" body:@{@"name":channel}];
}

-(void) pushClientManagerDidFailInSubscribe:(NSError *)error{
    [self sendEventWithName:@"onSubscribe" body:@{@"error":error}];
}

-(void) pushClientManagerDidUnsubscribed:(NSString *)channel{
    [self sendEventWithName:@"onUnsubscribe" body:@{@"name":channel}];
}

-(void) pushClientManagerDidFailInUnsubscribe:(NSError *)error{
    [self sendEventWithName:@"onUnsubscribe" body:@{@"error":error}];
}

-(void) handleNotificationOpened {
    NSDictionary *payload = (NSDictionary *)[_coldStartNotificationResult valueForKey:@"message"];
    if (payload) {
        NSString *messageId = [PushClientManager.defaultManager getMessageIdFromPayload:payload];
        if (_coldStartNotificationResult && messageId && (!_lastNotificationId || ![_lastNotificationId isEqualToString:messageId])) {
            _lastNotificationId = messageId;
            [self sendEventWithName:@"notificationOpened" body:_coldStartNotificationResult];
            _coldStartNotificationResult = nil;
        }
    }
}

+(NSDictionary *) notificationOpened:(NSDictionary *) payload actionId:(NSString *) actionId {
    NSString *actionType;
    NSString *actionUrl;
    NSString *actionIdStr = actionId;
    NSArray *actions = [payload valueForKey:@"actions"];
    NSString *clickUrl = [payload valueForKey:@"clickUrl"];
    
    if (@available(iOS 10.0, *)) {
        if ([actionId containsString:UNNotificationDismissActionIdentifier]) {
            actionType = @"dismissed";
            actionIdStr = nil;
        } else if ([actionId containsString:UNNotificationDefaultActionIdentifier]) {
            actionType = @"opened";
            actionIdStr = nil;
        }
    } else {
        actionType = @"action_taken";
        actionIdStr = actionId;
        
        if (actionIdStr || !actions) {
            actionUrl = [AdpPushClient getActionUrlFrom:actionIdStr actions:actions];
        }
    }
    
    NSMutableDictionary *notificationData = [NSMutableDictionary new];
    
    if (actionType) {
        [notificationData setObject:actionType forKey:@"actionType"];
    }
    
    if (actionIdStr) {
        [notificationData setObject:actionIdStr forKey:@"actionId"];
    }
    
    if (actionUrl) {
        [notificationData setObject:actionUrl forKey:@"actionUrl"];
    } else if (clickUrl) {
        [notificationData setObject:clickUrl forKey:@"actionUrl"];
    }
    
    if (!payload) {
        _coldStartNotificationResult = nil;
        return notificationData;
    }
    
    [notificationData setObject:payload forKey:@"message"];
    
    _coldStartNotificationResult = notificationData;
    
    return notificationData;
}

+(NSDictionary *) notificationOpened:(NSDictionary *) payload {
    if (@available(iOS 10.0, *)) {
        return [AdpPushClient notificationOpened:payload actionId:UNNotificationDefaultActionIdentifier];
    } else {
        return [AdpPushClient notificationOpened:payload actionId:@"unknown"];
    }
}

-(void) invalidate {
    self.appId = nil;
}

-(void) userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler API_AVAILABLE(ios(10.0)) API_AVAILABLE(ios(10.0)) {
    [AdpPushClient notificationOpened:response.notification.request.content.userInfo actionId:response.actionIdentifier];
    
    if (self.bridge) {
        [self handleNotificationOpened];
    }
}

+(NSString *) getActionUrlFrom:(NSString *)actionId actions:(NSArray *)actions {
    NSString *actionUrl;
    for (NSDictionary *action in actions) {
        NSString *acId = [action valueForKey:@"id"];
        if ([acId containsString:actionId]) {
            actionUrl = [action valueForKey:@"url"];
        }
    }
    return actionUrl;
}

+(NSDictionary *) getFormattedData:(NSDictionary *)data {
    NSMutableDictionary *mutableData = [NSMutableDictionary.alloc init];
    for (NSString *key in [data allKeys]) {
        // check datetime type
        if ([key hasPrefix:@"@CHKDATE_"]) {
            NSString *actualKey = [key substringFromIndex:9];
            mutableData[actualKey] = [[Datetime alloc] initWithTimestamp:[data[key] longLongValue]];
        } else {
            mutableData[key] = data[key];
        }
    }
    return mutableData;
}

@end
