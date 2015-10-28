//
//  NSString+Transliteration.m
//  emma
//
//  Created by Peng Gu on 8/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "NSString+Transliteration.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation NSString (Transliteration)

- (NSString *)stringByTransliterateToLatin
{
    NSMutableString *latin = [self mutableCopy];
    CFMutableStringRef latinRef = (__bridge CFMutableStringRef)latin;
    
    CFStringTransform(latinRef, NULL, kCFStringTransformToLatin, NO);
    CFStringTransform(latinRef, NULL, kCFStringTransformStripCombiningMarks, NO);
    
    return latin;
}


- (NSString *)transliteratedFirstCharacter
{
    if (self.length > 0) {
        NSString *latin = [self stringByTransliterateToLatin];
        return [latin substringToIndex:1];
    }
    return nil;
}


- (unichar)uppercaseFirstCharacter
{
    if (self.length > 0) {
        return [[self uppercaseString] characterAtIndex:0];
    }
    return NULL;
}


@end
