//
//  GLLinkLabel.m
//  GLQuestionKit
//
//  Created by ltebean on 15/7/24.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLLinkLabel.h"

#import <Foundation/Foundation.h>
#import <GLFoundation/GLTheme.h>

#define setRectHeight(rect, height) CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height)
#define setRectWidth(rect, width) CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height)
#define setRectX(rect, x) CGRectMake(x, rect.origin.y, rect.size.width, rect.size.height)
#define setRectY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)

@interface GLLinkLabel()
{
    NSMutableDictionary *callbacks;
    NSMutableDictionary *keyWordLocationToLink;
    NSMutableDictionary *rectToLink;
    NSMutableArray *keyWordsLocationInLowerCase;
}

@property (readwrite, nonatomic, strong) NSTextCheckingResult *activeLink;
@end

@implementation GLLinkLabel

- (void)awakeFromNib {
    self.useUnderline = YES;
    self.useHyperlinkColor = YES;
    self.userInteractionEnabled = YES;
    self.lineBreakMode = NSLineBreakByWordWrapping;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.useUnderline = YES;
        self.useHyperlinkColor = YES;
    }
    return self;
}

- (void)clearCallbacks
{
    rectToLink = nil;
    
    // a hack way to solve underline style cannot start from position 0 issue under iOS8
    NSMutableAttributedString *_t = [self.attributedText mutableCopy];
    [_t addAttribute:NSUnderlineStyleAttributeName
               value:@(NSUnderlinePatternSolid) range:NSMakeRange(0, _t.length)];
    self.attributedText = _t;
}

- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw
{
    [self setCallback:cb forKeyword:kw caseSensitive:YES];
}

- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw caseSensitive:(BOOL)caseSensitive
{
    if (!kw) {
        return;
    }
    
    NSString *kwInLowerCase = [kw lowercaseString];
    NSString *wholeStringInLowerCase = [self.text lowercaseString];
    NSRange kwRange = [wholeStringInLowerCase rangeOfString:kwInLowerCase];
    
    if (kwRange.location == NSNotFound) {
        return;
    }
    
    if(!callbacks){
        callbacks = [NSMutableDictionary dictionary];
    }
    
    [callbacks setObject:cb forKey:kw];
    
    NSMutableDictionary *linkAttrs = [NSMutableDictionary dictionary];
    if (self.useHyperlinkColor) {
        [linkAttrs setObject:UIColorFromRGB(0x4751CE) forKey:
         NSForegroundColorAttributeName];
    }
    if (self.useUnderline) {
        [linkAttrs setObject:[NSNumber numberWithInt:NSUnderlineStyleSingle] forKey:NSUnderlineStyleAttributeName];
    }
    
    NSString *str = self.attributedText.string;
    if (!str) {
        return;
    }
    
    NSMutableAttributedString *mAttrStr = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    
    NSRegularExpressionOptions options = NSRegularExpressionUseUnicodeWordBoundaries;
    if (!caseSensitive) {
        options |= NSRegularExpressionCaseInsensitive;
    }
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:[NSString stringWithFormat:@"\\b%@\\b", kw]
                                                                           options:options
                                                                             error:nil];
    
    NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    
    keyWordsLocationInLowerCase = [NSMutableArray array];
    keyWordLocationToLink = [NSMutableDictionary dictionary];
    
    for (NSTextCheckingResult *match in matches) {
        NSMutableDictionary *attrsCopy = [NSMutableDictionary dictionaryWithDictionary:[linkAttrs copy]];
        [mAttrStr enumerateAttributesInRange:match.range options:
         NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                  usingBlock:^(NSDictionary *attrs, NSRange range, BOOL *stop) {
                                      
                                      NSMutableDictionary *temp = [NSMutableDictionary dictionaryWithDictionary:attrs];
                                      [temp addEntriesFromDictionary:attrsCopy];//attrsCopy will override temp
                                      [attrsCopy addEntriesFromDictionary:temp];
                                  }];
        
        NSAttributedString *attrSubText = [[NSAttributedString alloc] initWithString:[str substringWithRange:match.range] attributes:attrsCopy];
        NSMutableAttributedString *mAttrSubText = [[NSMutableAttributedString alloc] initWithAttributedString:attrSubText];
        [mAttrSubText addAttribute:NSLinkAttributeName value:kw range:NSMakeRange(0, kw.length)];
        [mAttrSubText addAttribute:NSLinkAttributeCallback value:cb range:NSMakeRange(0, kw.length)];
        [mAttrStr replaceCharactersInRange:match.range withAttributedString:attrSubText];
        
        [keyWordsLocationInLowerCase addObject:[NSValue valueWithRange:match.range]];
        NSTextCheckingResult *link = [NSTextCheckingResult linkCheckingResultWithRange:match.range URL:[NSURL URLWithString:[kw stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        keyWordLocationToLink[[NSValue valueWithRange:match.range]] = link;
    }
    
    self.attributedText = mAttrStr;
    
    [self linkRects];
}

- (LinkClickedCallback)callbackForKeyword:(NSString *)kw
{
    if (!callbacks) {
        callbacks = [NSMutableDictionary dictionary];
    }
    
    LinkClickedCallback cb = ^(NSString *str){};
    if (kw && [[callbacks allKeys] containsObject:kw]) {
        cb = [callbacks objectForKey:kw];
    }
    
    return cb;
}

- (void)linkRects {
    NSMutableDictionary *keyWordLocationToRect = [NSMutableDictionary dictionary];
    
    if ( self.lineBreakMode != NSLineBreakByWordWrapping )
    {
        return;
    }
    
    //    NSCharacterSet* wordSeparators = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableCharacterSet *wordSeparators = [[NSMutableCharacterSet alloc] init];
    [wordSeparators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [wordSeparators formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    
    NSString* currentLine = self.attributedText.string;
    NSAttributedString *currentAttrLine = self.attributedText;
    CGRect currentRect = CGRectZero;
    NSInteger textLength = [self.attributedText.string length];
    
    NSRange rCurrentLine = NSMakeRange(0, textLength);
    NSRange rWhitespace = NSMakeRange(0,0);
    NSRange rRemainingText = NSMakeRange(0, textLength);
    BOOL done = NO;
    while ( !done )
    {
        // determine the next whitespace word separator position
        rWhitespace.location = rWhitespace.location + rWhitespace.length;
        NSInteger currentWordLocation = rWhitespace.location;
        rWhitespace.length = textLength - rWhitespace.location;
        rWhitespace = [self.text rangeOfCharacterFromSet: wordSeparators options: NSCaseInsensitiveSearch range: rWhitespace];
        if ( rWhitespace.location == NSNotFound )
        {
            rWhitespace.location = textLength;
            done = YES;
        }
        NSInteger currentWordLength = rWhitespace.location - currentWordLocation;
        if (currentWordLength < 0) {
            break;
        }
        
        NSRange rCurrentWord = NSMakeRange(currentWordLocation, currentWordLength);
        
        if (rRemainingText.location > rWhitespace.location) {
            break;
        }
        NSRange rTest = NSMakeRange(rRemainingText.location, rWhitespace.location-rRemainingText.location);
        
        NSAttributedString *attributedTextTest = [self.attributedText attributedSubstringFromRange:rTest];
        CGSize sizeTest = [attributedTextTest size];
        
        if ( sizeTest.width > self.bounds.size.width )
        {
            rRemainingText.location = rCurrentLine.location + rCurrentLine.length;
            if (textLength < rRemainingText.location) {
                break;
            }
            rRemainingText.length = textLength-rRemainingText.location;
            currentLine = [self.text substringWithRange: rRemainingText];
            currentRect = setRectY(currentRect, currentRect.origin.y + currentRect.size.height);
            continue;
        }
        
        rCurrentLine = rTest;
        currentAttrLine = attributedTextTest;
        
        currentRect = setRectHeight(currentRect, currentAttrLine.size.height);
        currentRect = setRectWidth(currentRect, currentAttrLine.size.width);
        
        for (NSValue *range in keyWordsLocationInLowerCase) {
            NSRange intersect = NSIntersectionRange([range rangeValue], rCurrentWord);
            if (intersect.location != NSNotFound && intersect.length > 0) {
                CGSize keyWordSize = [self.attributedText attributedSubstringFromRange:rCurrentWord].size;
                keyWordLocationToRect[[NSValue valueWithRange: rCurrentWord]] = @[@(currentRect.origin.x + currentRect.size.width - keyWordSize.width), @(currentRect.origin.y), @(keyWordSize.width), @(keyWordSize.height)];
            }
        }
    }
    
    if ([keyWordLocationToRect count] > 0) {
        if (!rectToLink) {
            rectToLink = [NSMutableDictionary dictionary];
        }
        CGRect paragraphRect =
        [self.attributedText boundingRectWithSize:CGSizeMake(self.bounds.size.width, CGFLOAT_MAX)
                                          options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                          context:nil];
        CGFloat yOffset = (self.bounds.size.height - roundf(paragraphRect.size.height)) * .5f;
        for (NSValue *keyWordLocation in keyWordLocationToRect) {
            NSArray *rectParameters = keyWordLocationToRect[keyWordLocation];
            NSArray *rectParametersAfterAdjust = @[rectParameters[0], @([rectParameters[1] floatValue] + yOffset), rectParameters[2], rectParameters[3]];
            id link = [self linkAtRange:[keyWordLocation rangeValue] ofMap:keyWordLocationToLink];
            if (link) {
                rectToLink[rectParametersAfterAdjust] = link;
            }
        }
    }
}

- (id)linkAtRange:(NSRange)range ofMap:(NSDictionary *) dic{
    for (NSValue *k in dic.allKeys) {
        NSRange r = [k rangeValue];
        if (range.location >= r.location && ((range.location+range.length) <= (r.location+r.length))) {
            return dic[k];
        }
    }
    
    return nil;
}

- (NSTextCheckingResult *)linkAtPoint:(CGPoint)p {
    if (!rectToLink || [rectToLink count] == 0) {
        return nil;
    }
    for (NSArray *rectParameters in rectToLink) {
        CGFloat x = [rectParameters[0] floatValue], y = [rectParameters[1] floatValue], w = [rectParameters[2] floatValue], h = [rectParameters[3] floatValue];
        if (p.x >= x - w * .5f && p.x <= x + w * 1.5f && p.y >= y - h * .5f && p.y <= y + h * 1.5f) {
            return rectToLink[rectParameters];
        }
    }
    return nil;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    self.activeLink = [self linkAtPoint:[touch locationInView:self]];
    
    if (!self.activeLink) {
        [super touchesBegan:touches withEvent:event];
    }
    
}

- (void)touchesMoved:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        UITouch *touch = [touches anyObject];
        
        if (self.activeLink != [self linkAtPoint:[touch locationInView:self]]) {
            self.activeLink = nil;
        }
    } else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    
    if (self.activeLink) {
        
        NSTextCheckingResult *result = self.activeLink;
        self.activeLink = nil;
        
        switch (result.resultType) {
            case NSTextCheckingTypeLink:{
                NSString *str = [[result.URL absoluteString] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                LinkClickedCallback cb = [self callbackForKeyword:str];
                cb(str);
            }
                break;
                
            default:
                break;
        }
        
    } else {
        [super touchesEnded:touches withEvent:event];
    }
}

- (void)touchesCancelled:(NSSet *)touches
               withEvent:(UIEvent *)event
{
    if (self.activeLink) {
        self.activeLink = nil;
    } else {
        [super touchesCancelled:touches withEvent:event];
    }
}
@end