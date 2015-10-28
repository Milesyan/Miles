//
//  NSString+Markdown.h
//  kaylee
//
//  Created by Allen Hsu on 3/12/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Markdown)

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize color:(UIColor *)color;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color alignment:(NSTextAlignment)alignment;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color boldColor:(UIColor *)boldColor alignment:(NSTextAlignment)alignment;
+ (NSRange)findPair:(NSString *)pattern inString:(NSString *)source;

+ (NSAttributedString *)addFont:(UIFont *)font toAttributed:(NSAttributedString *)aString;

@end
