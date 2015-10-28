//
//  GLUtils.m
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLUtils.h"

#define INCH_TO_CM      2.54
#define KG_TO_POUNDS    2.2

CGAffineTransform CGAffineTransformFromRectToRect(CGRect fromRect, CGRect toRect)
{
    CGAffineTransform scale = CGAffineTransformMakeScale(toRect.size.width/fromRect.size.width, toRect.size.height/fromRect.size.height);
    CGAffineTransform trans2 = CGAffineTransformMakeTranslation(toRect.origin.x + toRect.size.width / 2.0 - (fromRect.origin.x + fromRect.size.width / 2.0),
                                                                toRect.origin.y + toRect.size.height / 2.0 - (fromRect.origin.y + fromRect.size.height / 2.0));
    return CGAffineTransformConcat(scale, trans2);
}

@implementation GLUtils

+ (void)performInMainQueueAfter:(NSTimeInterval)seconds callback:(void (^)(void))callback {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC), dispatch_get_main_queue(), callback);
}

+ (id)getDefaultsForKey:(NSString *)key {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

+ (void)setDefaultsForKey:(NSString *)key withValue:(id)val {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (val != nil) {
        [defaults setObject:val forKey:key];
    }
    else {
        [defaults removeObjectForKey:key];
    }
    [defaults synchronize];
}

+ (BOOL)isValidEmail:(NSString *)string {
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:string];
}

+ (float)KGFromPounds:(int)pounds {
    return pounds / KG_TO_POUNDS;
}

+ (int)poundsFromKG:(float)kg {
    return kg * KG_TO_POUNDS + 0.5;
}

+ (int)inchesFromCm:(CGFloat)cm {
    return (cm / INCH_TO_CM + 0.5);
}

+ (float)cmFromInches:(int)inches {
    return inches * INCH_TO_CM;
}

+ (UIWindow *)keyWindow {
    if ([[UIApplication sharedApplication].keyWindow isMemberOfClass:[UIWindow class]]) {
        return [UIApplication sharedApplication].keyWindow;
    }
    for (UIWindow *window in [[UIApplication sharedApplication].windows reverseObjectEnumerator]) {
        if ([window isMemberOfClass:[UIWindow class]]) {
            return window;
        }
    }
    return nil;
}

+ (NSCalendar *)calendar {
    //    GLLog(@"Call for calendar !!, thread = %@", [NSOperationQueue currentQueue]);
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSCalendar *cal = threadDictionary[@"calendar"];
    if (!cal) {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        cal.locale = [NSLocale currentLocale];
        threadDictionary[@"calendar"] = cal;
    }
    return cal;
}


@end
