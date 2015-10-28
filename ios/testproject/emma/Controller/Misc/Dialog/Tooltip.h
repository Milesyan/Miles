//
//  Tooltip.h
//  emma
//
//  Created by Eric Xu on 10/14/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UILinkLabel.h"

#define SCHEME_TOOLTIP  @"tooltip"

@interface Tooltip : NSObject

+ (void)tip:(NSString *)tip;
+ (NSArray *)keywords;
+ (NSArray *)keywordsOrderByLength;
+ (void)updateKeywords:(NSArray *)newKeywords;
+ (void)setCallbackForAllKeywordOnLabel:(UILinkLabel *)label;
+ (void)setCallbackForAllKeywordOnLabel:(UILinkLabel *)label caseSensitive:(BOOL)caseSensitive;
+ (NSString *)replaceTermLinksInHtml:(NSString *)html caseSensitive:(BOOL)caseSensitive;

@end
