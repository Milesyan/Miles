//
//  NSString+Utils.m
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "NSString+Utils.h"

@implementation NSString (Utils)

+ (NSString *)capitalizeFirstOnlyFor:(NSString *)string {
    return [self catstr:[[string substringToIndex:1] capitalizedString],
        [string substringFromIndex:1], nil];
}

+ (NSString *)catstr:(NSString *)firstStr, ... {
    NSString *resultStr = @"";
    NSString *eachStr;
    va_list strList;
    if(firstStr) {
        resultStr = [resultStr stringByAppendingString:firstStr];
        va_start(strList, firstStr);
        eachStr = va_arg(strList, NSString *);
        while (eachStr) {
            resultStr = [resultStr stringByAppendingString:eachStr];
            eachStr = va_arg(strList, NSString *);
        }
        va_end(strList);
    }
    return resultStr;
}

+ (NSString *)catobj:(id)first, ... {
    NSString *resultStr = @"";
    id each;
    va_list strList;
    if(first) {
        NSString *firstStr = [first isKindOfClass:[NSString class]]
            ? first : [first stringValue];
        resultStr = [resultStr stringByAppendingString:firstStr];
        va_start(strList, first);
        each = va_arg(strList, id);
        while (each) {
            NSString *eachStr = [each isKindOfClass:[NSString class]]
                ? each : [each stringValue];
            resultStr = [resultStr stringByAppendingString:eachStr];
            each = va_arg(strList, id);
        }
        va_end(strList);
    }
    return resultStr;
}

+ (NSString *)timeElapsedString:(unsigned int)timestamp
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - timestamp;
    if (interval < 1.0) {
        return @"Just now";
    }
    if (interval < 60.0) {
        unsigned int num = floor(interval);
        return [NSString stringWithFormat:@"%d %@ ago", num, num > 1 ? @"secs" : @"sec"];
    }
    interval /= 60.0;
    if (interval < 60.0) {
        unsigned int num = floor(interval);
        return [NSString stringWithFormat:@"%d %@ ago", num, num > 1 ? @"mins" : @"min"];
    }
    interval /= 60.0;
    if (interval < 24.0) {
        unsigned int num = floor(interval);
        return [NSString stringWithFormat:@"%d %@ ago", num, num > 1 ? @"hours" : @"hour"];
    }
    NSString *dateFormatString = [NSDateFormatter dateFormatFromTemplate:@"EEEdMMM" options:0 locale:[NSLocale currentLocale]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [dateFormatter setDateFormat:dateFormatString];
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

+ (NSString *)numberToShortIntString:(long long)num {
    NSString *u = @"";
    long long newNum = 0;
    if (num >= 1000000000) {
        u = @"b";
        newNum = num/1000000000;
    } else if (num >= 1000000) {
        u = @"m";
        newNum = num/1000000;
    } else if (num >= 1000) {
        u = @"k";
        newNum = num/1000;
    } else {
        newNum = num;
    }
    return [NSString stringWithFormat:@"%lld%@", newNum, u];
}

+ (BOOL)isEmptyString:(NSString *)s {
    return ![NSString isNotEmptyString:s];
}

+ (BOOL)isNotEmptyString:(NSString *)s {
    if ((!s) || ([s isEqualToString:@""])) {
        return NO;
    } else {
        return YES;
    }
}

- (NSString *)trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)stringByStrippingHtmlTags
{
    return [self stringByReplacingOccurrencesOfString:@"</?[a-z][^>]*>" withString:@"" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, self.length)];
    
}
- (NSNumber *)toNumber {
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterDecimalStyle];
    return [f numberFromString:self];
}

+ (NSString *)jsonStringify:(id)stringifiableObj {
    @try {
        NSString *result = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:stringifiableObj options:0 error:nil] encoding:NSUTF8StringEncoding];
        return result;
    }
    @catch (NSException *exception) {
        return nil;
    }
}

+ (id)jsonParse:(NSString *)stringified {
    if (!stringified) {
        return nil;
    }
    @try {
        NSData *data = [stringified dataUsingEncoding:NSUTF8StringEncoding];
        return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    }
    @catch (NSException *exception) {
        return nil;
    }
}

@end
