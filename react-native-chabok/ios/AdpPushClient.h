@import UserNotifications;
#import "React/RCTBridgeModule.h"
#import "React/RCTEventEmitter.h"
#import <AdpPushClient/AdpPushClient.h>

@interface AdpPushClient : RCTEventEmitter <RCTBridgeModule,RCTInvalidating>

-(instancetype) init;

@end
