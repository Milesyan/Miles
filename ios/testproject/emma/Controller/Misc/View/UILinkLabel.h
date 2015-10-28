//
//  UILinkLabel.h
//  emma
//
//  Created by Eric Xu on 10/16/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "UILabel+AutoLink.h"
#define NSLinkAttributeName @"NSLinkAttributeName"
#define NSLinkAttributeCallback @"NSLinkAttributeCallback"

typedef void (^LinkClickedCallback)(NSString *str);

@interface UILinkLabel : UILabel

@property (nonatomic) BOOL useUnderline;
@property (nonatomic) BOOL useHyperlinkColor;

- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw;
- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw caseSensitive:(BOOL)caseSensitive;
- (void)clearCallbacks;
- (LinkClickedCallback)callbackForKeyword:(NSString *)kw;

@end
