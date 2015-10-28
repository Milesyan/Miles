//
//  CrashReport.h
//  emma
//
//  Created by Ryan Ye on 8/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@interface CrashReport : NSObject

+ (void)start;
+ (void)leaveBreadcrumb:(NSString *)breadcrumb;
+ (void)setUserId:(NSString *)userId;

@end
