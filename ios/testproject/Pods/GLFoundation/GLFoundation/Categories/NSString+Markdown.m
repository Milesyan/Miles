//
//  NSString+Markdown.m
//  kaylee
//
//  Created by Allen Hsu on 3/12/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLFoundation.h"
#import "NSString+Markdown.h"

@implementation NSString (Markdown)

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize color:(UIColor *)color {
    return [self markdownToAttributedText:markdown fontSize:fontSize lineHeight:0 color:color];
}

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color {
    return [self markdownToAttributedText:markdown fontSize:fontSize lineHeight:lineHeight color:color alignment:NSTextAlignmentLeft];
}

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color alignment:(NSTextAlignment)alignment {
    return [self markdownToAttributedText:markdown fontSize:fontSize lineHeight:lineHeight color:color boldColor:color alignment:alignment];
}

+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color boldColor:(UIColor *)boldColor alignment:(NSTextAlignment)alignment {
    if (!markdown) {
        return nil;
    }
    NSMutableDictionary *baseAttr = [@{
       NSFontAttributeName : [GLTheme defaultFont:fontSize],
       NSForegroundColorAttributeName : color,
    } mutableCopy];
    if (lineHeight > 0) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = lineHeight;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = alignment;
        baseAttr[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    NSMutableDictionary *boldAttr = [baseAttr mutableCopy];
    boldAttr[NSFontAttributeName] = [GLTheme boldFont:fontSize];
    boldAttr[NSForegroundColorAttributeName] = boldColor;
    NSMutableDictionary *semiBoldAttr = [baseAttr mutableCopy];
    semiBoldAttr[NSFontAttributeName] = [GLTheme semiBoldFont:fontSize];
    semiBoldAttr[NSForegroundColorAttributeName] = boldColor;
    NSMutableDictionary *linkAttr = [baseAttr mutableCopy];
    linkAttr[NSFontAttributeName] = [GLTheme boldFont:fontSize];
    linkAttr[NSForegroundColorAttributeName] = UIColorFromRGB(0x4751CE);
    linkAttr[NSUnderlineStyleAttributeName] = [NSNumber numberWithInt:NSUnderlineStyleSingle];

    NSDictionary *styleAttrs = @{
        @"**" :  boldAttr,
        @"##" : linkAttr,
        @"$$" : semiBoldAttr,
    };
    NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:markdown attributes:baseAttr];
    for (NSString *ctrlStr in styleAttrs) {
        NSDictionary *attr = styleAttrs[ctrlStr];
        NSRange range = [self findPair:ctrlStr inString:[attrText string]];
        while(range.location != NSNotFound) {
            NSString *subText = [[attrText string] substringWithRange:range];
            subText = [subText stringByReplacingOccurrencesOfString:ctrlStr withString:@""];
            NSAttributedString *attrSubText = [[NSAttributedString alloc] initWithString:subText attributes:attr];
            [attrText replaceCharactersInRange:range withAttributedString:attrSubText];
            range = [self findPair:ctrlStr inString:[attrText string]];
        }
    }
    return attrText;
}

+ (NSRange)findPair:(NSString *)pattern inString:(NSString *)source {
    NSRange start = [source rangeOfString:pattern];
    if (start.location == NSNotFound)
        return NSMakeRange(NSNotFound, 0);
    NSRange end = [source rangeOfString:pattern options:0 range:NSMakeRange(start.location + start.length, source.length - (start.location + start.length))];
    if (end.location == NSNotFound)
        return NSMakeRange(NSNotFound, 0);
    return NSMakeRange(start.location, end.location + end.length - start.location);
}

+ (NSAttributedString *)addFont:(UIFont *)font toAttributed:(NSAttributedString *)aString {
    NSDictionary * fontAttr = @{NSFontAttributeName:font};
    NSMutableAttributedString * s = [[NSMutableAttributedString alloc] initWithAttributedString:aString];
    [s addAttributes:fontAttr range:NSMakeRange(0, s.length)];
    return s;
}

@end
