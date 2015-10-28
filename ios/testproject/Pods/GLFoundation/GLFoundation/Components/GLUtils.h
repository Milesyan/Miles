//
//  GLUtils.h
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UIView+Helpers.h"
#import "NSString+Utils.h"
#import "UIColor+Utils.h"

#define IOS7_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#define IOS8_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)
#define IOS9_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
#define STATUSBAR_DELTA_6_FROM_7 ((IOS7_OR_ABOVE) ? 0 : -20)

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define STATUSBAR_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

extern CGAffineTransform CGAffineTransformFromRectToRect(CGRect fromRect, CGRect toRect);

@interface GLUtils : NSObject

+ (void)performInMainQueueAfter:(NSTimeInterval)seconds callback:(void (^)(void))callback;
+ (id)getDefaultsForKey:(NSString *)key;
+ (void)setDefaultsForKey:(NSString *)key withValue:(id)val;

+ (BOOL)isValidEmail:(NSString *)string;
+ (int)poundsFromKG:(float)kg;
+ (float)KGFromPounds:(int)pounds;
+ (int)inchesFromCm:(CGFloat)cm;
+ (float)cmFromInches:(int)inches;
+ (UIWindow *)keyWindow;

+ (NSCalendar *)calendar;

@end
