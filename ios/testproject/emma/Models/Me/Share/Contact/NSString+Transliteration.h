//
//  NSString+Transliteration.h
//  emma
//
//  Created by Peng Gu on 8/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Transliteration)

- (NSString *)stringByTransliterateToLatin;
- (NSString *)transliteratedFirstCharacter;
- (unichar)uppercaseFirstCharacter;

@end
