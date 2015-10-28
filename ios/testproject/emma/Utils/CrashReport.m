//
//  CrashReport.m
//  emma
//
//  Created by Ryan Ye on 8/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "CrashReport.h"

@implementation CrashReport

+ (void)start {
    // Setup Fabric with Crashlytics
    [Fabric with:@[CrashlyticsKit]];
#ifdef DEBUG
    [[Fabric sharedSDK] setDebug:YES];
    [[Crashlytics sharedInstance] setDebugMode:YES];
#endif
}

+ (void)setUserId:(NSString *)userId {
    [Crashlytics setUserIdentifier:userId];
}

+ (void)leaveBreadcrumb:(NSString *)breadcrumb {
    GLLog(@"leaveBreadcrumb: %@", breadcrumb);
    if (breadcrumb) {
        @try {
            CLSNSLog(@"Breadcrumb: %@", breadcrumb);
        }
        @catch (NSException *exception) {
            GLLog(@"Leave bread crumb exception:\n%@", exception);
        }
    }
}
@end
