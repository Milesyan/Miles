//
//  NSString+Utils.h
//  GLFoundation
//
//  Created by Allen Hsu on 8/27/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define catstr(f, ...) [NSString catstr:f, ##__VA_ARGS__]
#define catobj(o, ...) [NSString catobj:o, ##__VA_ARGS__]
#define capstr(s) [NSString capitalizeFirstOnlyFor:s]

@interface NSString (Utils)

+ (NSString *)capitalizeFirstOnlyFor:(NSString *)string;
+ (NSString *)catstr:(NSString *)firstStr, ...;
+ (NSString *)catobj:(id)first, ...;
+ (NSString *)timeElapsedString:(unsigned int)timestamp;
+ (BOOL)isEmptyString:(NSString *)s;
+ (BOOL)isNotEmptyString:(NSString *)s;
+ (NSString *)numberToShortIntString:(long long)num;

- (NSString *)trim;
- (NSString *)stringByStrippingHtmlTags;
- (NSNumber *)toNumber;

+ (NSString *)jsonStringify:(id)stringifiableObj;
+ (id)jsonParse:(NSString *)stringified;

@end
