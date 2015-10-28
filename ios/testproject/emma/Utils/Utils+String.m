//
//  Utils+String.m
//  emma
//
//  Created by Xin Zhao on 5/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Utils+String.h"

@implementation Utils (String)

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

@end
