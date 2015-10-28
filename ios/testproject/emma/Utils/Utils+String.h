//
//  Utils+String.h
//  emma
//
//  Created by Xin Zhao on 5/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Utils.h"

#define catstr(f, ...) [Utils catstr:f, ##__VA_ARGS__]
#define capstr(s) [Utils capitalizeFirstOnlyFor:s]

@interface Utils (String)

+ (NSString *)capitalizeFirstOnlyFor:(NSString *)string;
+ (NSString *)catstr:(NSString *)firstStr, ...;

@end
